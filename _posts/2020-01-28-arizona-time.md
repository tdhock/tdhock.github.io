---
layout: post
title: Arizona time
description: Why does internet tell people the wrong time?
---

Today I was supposed to pick up my intern Arnaud Liehrmann at the
local airport in Flagstaff, Arizona. According to the travel agency
PLUS VOYAGES the flight was supposed to take off from DFW (central
time zone) at 18:47 and land in FLG (mountain time zone) at 20:43.

However I got a text message "I just landed" from Arnaud at 20:08. Was
the plane very early? FlightAware says the plane took off at 18:39
and landed at 20:02. So I guess the plane actually was early.

I thought it may have been the same computer glitch which has caused
me problems for scheduling skype calls with people in different time
zones (interviews, etc). So I started reading about how computers keep
track of time zones and daylight savings time. Turns out there are a
couple of guys who keep a database of text files (tzdb) which contains
details about exactly when daylight savings time starts, ends, in
which places, and when those rules have changed in the past.

For example here is the
[northamerica](ftp://ftp.iana.org/tz/tzdb-2019c/northamerica) file in
tzdb:

```
# Now we turn to US areas that have diverged from the consensus since 1970.

# Arizona mostly uses MST.

# From Paul Eggert (2002-10-20):
#
# The information in the rest of this paragraph is derived from the
# Daylight Saving Time web page
# <http://www.dlapr.lib.az.us/links/daylight.htm> (2002-01-23)
# maintained by the Arizona State Library, Archives and Public Records.
# Between 1944-01-01 and 1944-04-01 the State of Arizona used standard
# time, but by federal law railroads, airlines, bus lines, military
# personnel, and some engaged in interstate commerce continued to
# observe war (i.e., daylight saving) time.  The 1944-03-17 Phoenix
# Gazette says that was the date the law changed, and that 04-01 was
# the date the state's clocks would change.  In 1945 the State of
# Arizona used standard time all year, again with exceptions only as
# mandated by federal law.  Arizona observed DST in 1967, but Arizona
# Laws 1968, ch. 183 (effective 1968-03-21) repealed DST.
#
# Shanks says the 1944 experiment came to an end on 1944-03-17.
# Go with the Arizona State Library instead.

# Zone	NAME		STDOFF	RULES	FORMAT	[UNTIL]
Zone America/Phoenix	-7:28:18 -	LMT	1883 Nov 18 11:31:42
			-7:00	US	M%sT	1944 Jan  1  0:01
			-7:00	-	MST	1944 Apr  1  0:01
			-7:00	US	M%sT	1944 Oct  1  0:01
			-7:00	-	MST	1967
			-7:00	US	M%sT	1968 Mar 21
			-7:00	-	MST
# From Arthur David Olson (1988-02-13):
# A writer from the Inter Tribal Council of Arizona, Inc.,
# notes in private correspondence dated 1987-12-28 that "Presently, only the
# Navajo Nation participates in the Daylight Saving Time policy, due to its
# large size and location in three states."  (The "only" means that other
# tribal nations don't use DST.)
```

Read [tz-how-to.html](ftp://ftp.iana.org/tz/tzdb-2019c/tz-how-to.html)
for an explanation about how to decipher/understand these files.

Apparently Arizona and Hawaii are the only states which do not observe
daylight savings time. In regards to Arizona, that is consistent with
the most recent rule listed in the file shown above. 

So if the computer programmers are correctly interpreting the tzdb,
then there should not be any problems. Is the issue that some
programmers do not consult tzdb, and just assume that all of USA
observes daylight savings time?
