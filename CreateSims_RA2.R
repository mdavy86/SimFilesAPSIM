# reads a "base" sim file (XML)
# finds out a list of met files to run
# Creates multiple sim files pointing out to these met files
# Change some info in XMLs (e.g. dates and hybrids)

library(XML)

# Set folder locations
setwd = "C:\\Apsim_dev\\Projects\\CCII\\RA2_CaseStudy\\marcus\\"

# Select Met folder locations (to read weather data from)
metFolder = getwd()

# Base sim
baseSimFolder = "C:\\Apsim_dev\\Projects\\CCII\\RA2_CaseStudy\\marcus\\baseSim"

# Output place for new sim files
simFolder = "C:\\Apsim_dev\\Projects\\CCII\\RA2_CaseStudy\\marcus"

# Define soil type names
soilTypes = c("high", "low")

for(so in 1:length(soilTypes)) {
  soils = soilTypes[so]
  rootSimFile = paste0(baseSimFolder,soils,".sim") #"C:\\Apsim_dev\\Projects\\CCII\\RA2_CaseStudy\\simFiles\\baseSim\\HigWHCSim.sim"

#rootSimFile = "C:\\Apsim_dev\\Projects\\CCII\\RA2_CaseStudy\\simFiles\\baseSim\\HigWHCSim.sim"
#soils = "high" # as .sim above

#rootSimFile = "C:\\Apsim_dev\\Projects\\CCII\\RA2_CaseStudy\\simFiles\\baseSim\\LowWHCSim.sim"
#soils = "low" # as .sim above

print(paste0("Running: ",rootSimFile))

# finds out met files to point to
# metFiles = list.files(metFolder,pattern='.met', full.names=FALSE) # Option 1: gets all met files in a folder
#load("C:\\Apsim_dev\\Projects\\CCII\\RA2_CaseStudy\\filter\\Filter_ArableKaituna.RData", .GlobalEnv) # Option 2: gets a list of grid-cell/files selected (LU layer in this case)
load("C:\\Apsim_dev\\Projects\\CCII\\RA2_CaseStudy\\source\\filtersAnneGaelle\\Filter_LU_metList.RData", .GlobalEnv) # Filter for all Kaituna minus lakes (AnneGaelle-BiomaBGC)

metFiles = metList
length(metFiles)

# get data from the root (base) .sim file
#doc = xmlInternalTreeParse(rootSimFile)
doc = xmlTreeParse(rootSimFile, useInternalNodes = TRUE)
nodesMet = getNodeSet(doc, "//filename")
nodesOut = getNodeSet(doc, "//outputfile")
nodesStDate = getNodeSet(doc, "//start_date")
nodesEnDate = getNodeSet(doc, "//end_date")
nodesCV = getNodeSet(doc, "//CultivarName")

simNameRoot = xmlRoot(doc)

# Select the climate scanario names to run (!!!!! Atention !!!!!)
# loop across cvs and climates
climates = c("base", "fut1")
#climates = "fut1"
cultivars = c("short", "long")

for(cl in 1:length(climates)){

  for (cv in 1:length(cultivars)) {

    # print(c(climates[cl], cultivars[cv]))

    # change cultivar FIXME: it's change cultivars of all crops!
    lapply(nodesCV, function(n) {
      for (i in 1:length(cultivars)) {  ## only change names if crop has these cultivars
        if(xmlValue(n) == cultivars[i])
          xmlValue(n) = cultivars[cv]
      }
    })

    # choose dates for the current climate scenario
    if(climates[cl] == "base") {

      stDate = "01/01/1971"
      enDate = "01/01/2000"

    } else {

      stDate = "01/01/2069"
      enDate = "01/01/2099"
    }

    # change scenario
    lapply(nodesStDate, function(n) {
      xmlValue(n) = stDate
    })
    lapply(nodesEnDate, function(n) {
      xmlValue(n) = enDate
    })

    # # Loop through met file names to create one .sim file for each met file
    for(i in seq_along(metFiles)) {
      #for(i in 1:10) { # For testing
      # get file name from each met and creates file names and attributes to change in new XML files
      metName = metFiles[i]
      splitName = unlist(strsplit(metFiles[i],"[.]"))
     # simName = paste(splitName[1],".sim", sep = "")
      gridName = splitName[1]
      outName = paste(gridName, "_", climates[cl],"_", soils, "_", cultivars[cv],".out", sep = "")

      # change attribute name of simulation
      xmlAttrs(simNameRoot) = c(name = splitName[1])

      #  find address to point out to right met files
      newMetNode = paste(metFolder,metName,sep ="")

      # change met location
      lapply(nodesMet, function(n) {
        xmlValue(n) = newMetNode
      })

      # change outfile name
      lapply(nodesOut, function(n) {
        xmlValue(n) = outName
      })

      # FIXME: identation of saved XML file is corrupted when it has text but no problem with functionality
      saveXML(doc, file = paste(simFolder, gridName, "_", climates[cl],"_", soils, "_", cultivars[cv], ".sim", sep = ""), indent=TRUE)

    }  # END MET FILES
  } # END LOOP CULTIVARS
 } # END LOOP CLIMATES
} # END LOOP SOIL TYPES











