/*****************************************************************************************
**          Copyright(c) 2015-2026 MicroStrain by HBK. All rights reserved.             **
**                                                                                      **
**    MIT Licensed. See the included LICENSE file for a copy of the full MIT License.   **
*****************************************************************************************/

#pragma once

#include "mscl/MicroStrain/Wireless/Features/BaseStationFeatures_wsda2000.h"

namespace mscl
{
    //Class: BaseStationFeatures_wsdaPro
    //    Contains information on features for the WSDA-Pro.
    class BaseStationFeatures_wsdaPro : public BaseStationFeatures_wsda2000
    {
    public:
        ~BaseStationFeatures_wsdaPro() override = default;

        //Constructor: BaseStationFeatures_wsdaPro
        //    Creates a BaseStationFeatures_wsdaPro object.
        //
        //Parameters:
        //    info - A <BaseStationInfo> object representing standard information of the <BaseStation>.
        BaseStationFeatures_wsdaPro(const BaseStationInfo& info);
    };
} // namespace mscl
