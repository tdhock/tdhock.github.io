library(data.table)

pkglist <- tools::CRAN_package_db()
subject <- pkglist[["Maintainer"]]
stringr.maint <- stringr::str_match(subject, "^[\'\"]?([^\'\",(<]+).*<")[,2]

maybe.quote <- "[\'\"]?"
not.special <- "[^\'\",(<]+"
until.email <- ".*<"
nc.pattern <- list(
  "^",
  maybe.quote,
  maint=not.special, 
  until.email)

nc::capture_first_vec(
  subject,
  nc.pattern,
  engine="ICU")
subject[c(7574,9068,12641,12972)]

nc.maint <- nc::capture_first_vec(
  subject,
  nc.pattern,
  engine="ICU",
  nomatch.error=FALSE)

## they are the same
identical(nc.maint[["maint"]], stringr.maint)

stringr.pattern <- paste0(
  maybe.quote,
  "(", not.special, ")",
  until.email)
stringr.maint.pasted <- stringr::str_match(subject, stringr.pattern)[,2]

identical(stringr.maint.pasted, stringr.maint)

stringr.dt <- data.table(subject, stringr.maint)
stringr.dt[1:2]
stringr.dt[grepl("[(]", subject)][1:2]

maybe.email <- nc::quantifier(
  "\\s*<",
  email=".*",
  ">",
  "?")
email.dt <- nc::capture_first_vec(
  subject,
  "^",
  name=".*?",
  maybe.email,
  "$")
email.dt[order(nchar(email))]

grep("[(]", email.dt[["name"]], value=TRUE)[1:5]
maybe.nickname <- nc::quantifier(
  "[(]",
  nickname=".*",
  "[)]",
  "?")
nick.dt <- nc::capture_first_df(email.dt, name=list(
  "^",
  maybe.quote,
  before='[^("\']*',
  maybe.quote,
  maybe.nickname,
  after=".*?",
  maybe.quote,
  "$"))
nick.dt[nickname!=""][1:5]
nick.dt[, full := sub(" *$", "", gsub(" +", " ", paste(before, after)))]
nick.dt[nickname!=""][1:5, .(before, after, full)]
nick.dt[grepl("[\"']", full)]
nick.dt[, full.trans := stringi::stri_trans_general(full, "latin-ascii") ]

email.name.counts <- nick.dt[, .(count=.N), by=.(email, full.trans)]
email.name.counts[full.trans=="Toby Dylan Hocking"]
email.counts <- email.name.counts[, .(emails=.N), by=full.trans]
email.counts[full.trans=="Toby Dylan Hocking"]
table(email.counts$emails)
big.emails <- email.counts[3 < emails]
email.name.counts[big.emails, on="full.trans"]

my.i <- nick.dt[, which(full=="Toby Dylan Hocking")]
data.table(pkglist)[my.i, .(Package, Maintainer, Version)]

stringr.trimmed <- stringr::str_trim(stringr.maint)
as.list(structure(stringr.trimmed, names=subject)[grepl("[(]", subject)])

table(gsub("[^(]", "", subject), gsub("[^)]", "", subject))

orig.maint <- stringi::stri_trans_general(stringr.trimmed, "latin-ascii")
(orig.top20 <- data.table(orig.maint)[, .(
  count=.N
), by=orig.maint][order(-count)][1:20])

translation.different <- unique(data.table(
  stringr.trimmed, orig.maint)[stringr.trimmed != orig.maint])
translation.also.in.trimmed <- unique(stringr.trimmed[
  stringr.trimmed %in% translation.different$orig.maint])
translation.different[orig.maint %in% translation.also.in.trimmed]

nc.sorted <- nick.dt[, .(
  count=.N
), by=.(orig.maint=full.trans)][order(-count)]
nc.top20 <- nc.sorted[1:20]
identical(nc.top20, orig.top20)

unique(data.table(
  nc.maint, orig.maint
)[nc.maint != orig.maint | is.na(orig.maint)])


nc.sorted[, Rank := rank(-count)]
(N.maintainers <- nrow(nc.sorted))
nc.sorted[, percent := 100*Rank/N.maintainers]
nc.sorted[orig.maint=="Toby Dylan Hocking"]

unique(nc.sorted[, .(count, Rank, percent)])

