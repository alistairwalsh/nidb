/*=========================================================================

  Program: GDCM (Grassroots DICOM). A DICOM library

  Copyright (c) 2006-2011 Mathieu Malaterre
  All rights reserved.
  See Copyright.txt or http://gdcm.sourceforge.net/Copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
#include "gdcmTrace.h"

#include <iostream>
#include <fstream>

namespace gdcm
{
//-----------------------------------------------------------------------------
// Warning message level to be displayed
static bool DebugFlag   = false;
static bool WarningFlag = true;
static bool ErrorFlag   = true;
static std::ostream * src = &std::cerr;

void Trace::SetStream(std::ostream &os)
{
  src = &os;
}
std::ostream &Trace::GetStream()
{
  return *src;
}

//-----------------------------------------------------------------------------
// Constructor / Destructor
Trace::Trace()
{
  DebugFlag = WarningFlag = ErrorFlag = false;
}

Trace::~Trace()
{
}

void Trace::SetDebug(bool debug)  { DebugFlag = debug; }
void Trace::DebugOn()  { DebugFlag = true; }
void Trace::DebugOff() { DebugFlag = false; }
bool Trace::GetDebugFlag()
{
  return DebugFlag;
}

void Trace::SetWarning(bool warning)  { WarningFlag = warning; }
void Trace::WarningOn()  { WarningFlag = true; }
void Trace::WarningOff() { WarningFlag = false; }
bool Trace::GetWarningFlag()
{
  return WarningFlag;
}

void Trace::SetError(bool error)  { ErrorFlag = error; }
void Trace::ErrorOn()  { ErrorFlag = true; }
void Trace::ErrorOff() { ErrorFlag = false; }
bool Trace::GetErrorFlag()
{
  return ErrorFlag;
}

} // end namespace gdcm
