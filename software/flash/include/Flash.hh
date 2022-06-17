#ifndef Flash_hh
#define Flash_hh

/** @file Flash.hh

    Class for the flash memory on the AMC.

    Modeled after Flash class in the AMC13Tool code:
        amc13_v1_0_5/amc13/include/amc13/Flash.hh
    (some code is copied directly from there)

 */

#include "AMC.hh"

class Flash {

public:

  Flash(AMC* amc);

  uint32_t readStatusRegister();
  uint8_t readExtendedAddressRegister();
  uint32_t readID();
  std::vector<uint32_t> read(size_t nWords, uint32_t addr);
  void pageProgram(uint32_t addr, uint32_t* data);
  void subsectorErase(uint32_t addr);
  void sectorErase(uint32_t addr);
  void writeExtendedAddressRegister(uint8_t value);

  void programFirmware(const std::string& mcsFileName, uint32_t addr);
  void eraseFirmware(uint32_t addr, uint32_t sectors);

private:

  Flash(); // no default constructor

  void writeEnable();
  void waitForWriteDone();
  uint32_t addressSelect(uint32_t addr);

  void writeWBUF(size_t nWords, uint32_t* data);
  void initiateTransaction(size_t nWriteBytes, size_t nReadBytes);
  void readRBUF(size_t nWords, uint32_t* buffer);

  std::vector<uint32_t> firmwareFromMcs(const std::string& mcsFileName);
  uint32_t intFromString(const std::string& s, unsigned int pos, unsigned int n);

  size_t WBUF_SIZE;
  size_t RBUF_SIZE;
  size_t MAX_BYTES;
  
  AMC* m_amc;

}; // class Flash

#endif // Flash_hh
