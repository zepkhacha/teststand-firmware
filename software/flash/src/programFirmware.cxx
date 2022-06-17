/** @file programFirmware.cxx

    Software tool to program firmware into the Flash on the AMC.  MCS
    filenames must be of the release format: fc7_[image]_0xXXYYZZ.mcs.

    Usage: ./bin/programFirmware [crate numbers] [slot numbers] [mcs file]
*/

#include "uhal/uhal.hpp"
#include "uhal/log/exception.hpp"
#include "uhal/ProtocolUDP.hpp"
#include "AMC.hh"
#include "Flash.hh"
#include <ctype.h>
#include <string>
#include <sstream>
#include <iostream>

template <typename T>
std::string to_string(const T& n) {
  std::ostringstream stm;
  stm << n;
  return stm.str();
}

int main (int argc, char* argv[]) {
  uhal::disableLogging();

  // check for correct number of arguments
  if (argc != 5) {
    std::cout << "Usage: ./bin/programFirmware [crate numbers] [slot numbers] [mcs file] [address table]" << std::endl;
    return 1;
  }

  std::string str; // local read buffer

  // split crate numbers by ','
  std::vector<std::string> splitCrateNumbers;
  std::stringstream ss1 ( argv[1] );
  while ( getline(ss1, str, ',') ) splitCrateNumbers.push_back(str);

  // split crate numbers by '-'
  std::vector<int> crateNumbers;
  for (int i = 0; i < splitCrateNumbers.size(); ++i) {
    std::vector<int> splitCrateRanges;
    std::stringstream ss2 ( splitCrateNumbers.at(i) );
    while ( getline(ss2, str, '-') ) splitCrateRanges.push_back( atoi(str.c_str()) );

    if (splitCrateRanges.size() == 1)
      crateNumbers.push_back( splitCrateRanges.at(0) );
    else {
      for (int j = splitCrateRanges.at(0); j <= splitCrateRanges.at(1); ++j) {
	crateNumbers.push_back(j);
      }
    }
  }

  // split slot numbers by ','
  std::vector<std::string> splitSlotNumbers;
  std::stringstream ss3 ( argv[2] );
  while ( getline(ss3, str, ',') ) splitSlotNumbers.push_back(str);

  // split slot numbers by '-'
  std::vector<int> slotNumbers;
  for (int i = 0; i < splitSlotNumbers.size(); ++i) {
    std::vector<int> splitSlotRanges;
    std::stringstream ss4 ( splitSlotNumbers.at(i) );
    while ( getline(ss4, str, '-') ) splitSlotRanges.push_back( atoi(str.c_str()) );
    
    if (splitSlotRanges.size() == 1)
      slotNumbers.push_back( splitSlotRanges.at(0) );
    else {
      for (int j = splitSlotRanges.at(0); j <= splitSlotRanges.at(1); ++j) {
	slotNumbers.push_back(j);
      }
    }
  }

  for (int iCrate = 0; iCrate < crateNumbers.size(); ++iCrate) {
    for (int iSlot = 0; iSlot < slotNumbers.size(); ++iSlot) {
      std::string uri = "ipbusudp-2.0://192.168."+to_string( crateNumbers.at(iCrate) )+"."+to_string( slotNumbers.at(iSlot) )+":50001";
      // std::string addressTable = "file://../address_tables/address_table.xml";
      std::string addressTable = "file://";
      addressTable.append(argv[4]);
      std::cout << "Address table url: " << addressTable << std::endl;
      uhal::HwInterface hw = uhal::ConnectionManager::getDevice("hw_id", uri, addressTable);

      AMC amc(&hw);
      Flash flash(&amc);

      // split file path by '/'
      std::vector<std::string> filePaths;
      std::stringstream ss5 ( argv[3] );
      while ( getline(ss5, str, '/') ) filePaths.push_back(str);
      std::string mcsFileName = filePaths.at( filePaths.size() - 1 );

      int fileNameLength = mcsFileName.length();
      std::string majorRevision = mcsFileName.substr(fileNameLength - 10, 2);
      std::string minorRevision = mcsFileName.substr(fileNameLength -  8, 2);
      std::string patchRevision = mcsFileName.substr(fileNameLength -  6, 2);
      std::string imageName     = mcsFileName.substr(4, fileNameLength - 17);

      std::cout << "Crate ";
      if (crateNumbers.at(iCrate) < 10) std::cout << "0";
      std::cout << to_string( crateNumbers.at(iCrate) ) << ", ";

      std::cout << "Slot ";
      if (slotNumbers.at(iSlot) < 10) std::cout << "0";
      std::cout << to_string( slotNumbers.at(iSlot) ) << " : ";

      if (imageName == "encoder") std::cout << "Encoder v";
      if (imageName == "fanout")  std::cout << "Fanout v";

      std::cout << std::strtol(majorRevision.c_str(), NULL, 16) << ".";
      std::cout << std::strtol(minorRevision.c_str(), NULL, 16) << ".";
      std::cout << std::strtol(patchRevision.c_str(), NULL, 16) << std::endl;
      
      uint32_t addr = 0x00000000;
      flash.programFirmware(argv[3], addr);
      flash.writeExtendedAddressRegister(0);
    }
  }

  return 0;
}
