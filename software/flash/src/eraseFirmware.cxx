/** @file eraseFirmware.cxx

    Software tool to erase firmware from the Flash on the AMC.

    Usage: ./bin/eraseFirmware [crate numbers] [slot numbers]
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
  if (argc != 3) {
    std::cout << "Usage: ./bin/eraseFirmware [crate numbers] [slot numbers]" << std::endl;
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
      std::string addressTable = "file://../address_tables/address_table.xml";
      uhal::HwInterface hw = uhal::ConnectionManager::getDevice("hw_id", uri, addressTable);

      AMC amc(&hw);
      Flash flash(&amc);

      std::cout << "Crate ";
      if (crateNumbers.at(iCrate) < 10) std::cout << "0";
      std::cout << to_string( crateNumbers.at(iCrate) ) << ", ";

      std::cout << "Slot ";
      if (slotNumbers.at(iSlot) < 10) std::cout << "0";
      std::cout << to_string( slotNumbers.at(iSlot) ) << std::endl;
        
      bool passed = false;
      while (!passed) {
	try {
	  uint32_t addr = 0x00000000;
	  uint32_t sectors = 0xFF;
	  flash.eraseFirmware(addr, sectors);
	  flash.writeExtendedAddressRegister(0);
	  passed = true;
	} catch (uhal::exception::UdpTimeout& ex) {
	  std::cout << "\nCaught uHAL timeout exception. Retrying..." << std::endl;
	}
      }
    }
  }

  return 0;
}
