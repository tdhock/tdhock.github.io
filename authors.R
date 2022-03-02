subject <- gsub("\n", " ", "Feng Tao, Yuanyuan Huang, Bruce A. Hungate, Stefano Manzoni, Serita
D. Frey, Michael W. I. Schmidt, Markus Reichstein, Nuno Carvalhais,
Philippe Ciais, Lifen Jiang, Johannes Lehmann, Umakant Mishra, Gustaf
Hugelius, Toby D. Hocking, Xingjie Lu, Zheng Shi, Kostiantyn Viatkin,
Ronald Vargas, Yusuf Yigini, Christian Omuto, Ashish A. Malik,
Guillermo Peralta, Rosa Cuevas-Corona, Luciano E. DiPaolo, Isabel
Luotto, Cuijuan Liao, Yi-Shuang Liang, Vinisa S. Saynes, Xiaomeng
Huang, Yiqi Luo")
name.vec <- strsplit(subject, ", ")[[1]]
name.dt <- nc::capture_first_vec(
  name.vec,
  before=".*",
  " ",
  last="[^,]*")
name.dt[, initials := gsub("[^A-Z]", "", before)]
name.dt[, last.initials := paste(last, initials)]
paste(name.dt$last.initials, collapse=", ")
