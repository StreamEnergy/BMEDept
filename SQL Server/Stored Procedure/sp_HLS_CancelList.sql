USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_HLS_CancelList]    Script Date: 08/25/2014 12:16:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--USE [StreamInternal]
--GO

--/****** Object:  StoredProcedure [dbo].[sp_HLS_CustomerGainAndLosses_Daily]    Script Date: 08/18/2014 09:32:59 ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO


--/**********************************************************************************************
--==============================================================================================
--*********** Notes/Change Log ****************
----============================================================================================
--Date					Author						DESCRIPTION
--08/18/2014 			Jide Akintoye				CREATE Weekly HLS Cancellation list		


--**********************************************************************************************/

CREATE PROCEDURE [dbo].[sp_HLS_CancelList]
    ( @StartDate DATETIME ,
      @EndDate DATETIME 
    )
AS
    BEGIN

----/**BeginTest**/
--DECLARE @StartDate DATETIME = GETDATE()-6--'08//2014'
--DECLARE @EndDate DATETIME = GETDATE()--'06/15/2014'
----/**EndTest**/


        SELECT  'CustID' = VendorCustomerNumber ,
                'FirstName' = CONVERT(VARCHAR(225) , UPPER(SUBSTRING([FirstName] ,
                                                              1 , 1))
                + LOWER(SUBSTRING([FirstName] , 2 , 255))) ,
                'LastName' = CONVERT(VARCHAR(225) , UPPER(SUBSTRING([LastName] ,
                                                              1 , 1))
                + LOWER(SUBSTRING([LastName] , 2 , 255))) ,
                'Address' = [Address1] + ', ' + ISNULL([Address2] , '') ,
                [City] ,
                [State] ,
                [ZipCode] ,
                Email ,
                PrimaryPhone ,
                CustomerStatus ,
                EnrollDate ,
                CASE WHEN ProductCode = 'seidcrit01'
                     THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM)'
                     WHEN ProductCode = 'seidcrit02'
                     THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM) - Waive First Month Fee'
                     WHEN ProductCode = 'seidcr01'
                     THEN 'Gold HomeLife Services: 2 Bundle (ID,CM)'
                     WHEN ProductCode = 'seidcr02'
                     THEN 'Gold HomeLife Services: 2 Bundle (ID,CM) - Waive First Month Fee'
                     WHEN ProductCode = 'seidit02'
                     THEN 'Gold HomeLife Services: 2 Bundle (ID,Tech) - Waive First Month Fee'
                     WHEN ProductCode = 'seid01'
                     THEN 'Silver HomeLife Services: ID Theft (ID)'
                     WHEN ProductCode = 'seid02'
                     THEN 'Silver HomeLife Services: ID Theft (ID) - Waive First Month Fee'
                     WHEN ProductCode = 'seidcrit01'
                     THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM)'
                     WHEN ProductCode = 'seidcrit02'
                     THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM) - Waive First Month Fee'
                     WHEN ProductCode = 'seidcr01'
                     THEN 'Gold HomeLife Services: 2 Bundle (ID,CM)'
                     WHEN ProductCode = 'seidcr02'
                     THEN 'Gold HomeLife Services: 2 Bundle (ID,CM) - Waive First Month Fee'
                     WHEN ProductCode = 'secrit02'
                     THEN 'Gold HomeLife Services: 2 Bundle (Tech, CM) - Waive First Month Fee'
                     WHEN ProductCode = 'seidit01'
                     THEN 'Gold HomeLife Services: 2 Bundle (ID,IT)'
                     WHEN ProductCode = 'secrit01'
                     THEN 'Gold HomeLife Services: 2 Bundle (CM, IT)'
                     WHEN ProductCode = 'secr01'
                     THEN 'Silver HomeLife Services: Credit Monitoring (CM)'
                     WHEN ProductCode = 'secr02'
                     THEN 'Silver HomeLife Services: Credit Monitoring (CM) - Waive First Month Fee'
                     WHEN ProductCode = 'seidcrit01'
                     THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM)'
                     WHEN ProductCode = 'seidcrit02'
                     THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM) - Waive First Month Fee'
                     WHEN ProductCode = 'seidit02'
                     THEN 'Gold HomeLife Services: 2 Bundle (ID,Tech) - Waive First Month Fee'
                     WHEN ProductCode = 'secrit02'
                     THEN 'Gold HomeLife Services: 2 Bundle (Tech, CM) - Waive First Month Fee'
                     WHEN ProductCode = 'seit01'
                     THEN 'Silver HomeLife Services: Tech Support (Tech)'
                     WHEN ProductCode = 'seit02'
                     THEN 'Silver HomeLife Services: Tech Support (Tech) - Waive First Month Fee'
                     WHEN ProductCode = 'seatechftby'
                     THEN ' Add on Tech with free trial'
                     WHEN ProductCode = 'seatechby ' THEN 'Add on tech'
                     WHEN ProductCode = 'seaidftby'
                     THEN 'Add on ID with free trial'
                     WHEN ProductCode = 'seaidby' THEN 'Add on ID'
                     WHEN ProductCode = 'seacrftby'
                     THEN 'Add on Credit with free trial'
                     WHEN ProductCode = 'seacrby' THEN 'Add on Credit'
                     ELSE ProductCode
                END AS ProductCode ,
                'SalesSource' = SalesSource + ISNULL(' / ' + AgentID , '') ,
                'CancelDate' = MAX(CancelDate)
        FROM    dbo.HLS_Customers_Data
        WHERE   CustomerStatus = 'Cancelled'
                AND CancelDate IS NOT NULL
                AND CancelDate BETWEEN @StartDate AND @EndDate-->= GETDATE() - 6--8
                --AND VendorCustomerNumber = '214100881'
GROUP BY        VendorCustomerNumber ,
                [FirstName] ,
                [LastName] ,
                [Address1] + ', ' + ISNULL([Address2] , '') ,
        --[Address1]+ ' ' + [Address2] ,
                [City] ,
                [State] ,
                [ZipCode] ,
                Email ,
                PrimaryPhone ,
                CustomerStatus ,
                EnrollDate ,
                SalesSource ,
                AgentId ,
                ProductCode
        ORDER BY CancelDate DESC


    END
/*
SELECT  *
FROM    dbo.HLS_Customers_Data
WHERE   VendorCustomerNumber = '214294683'
--WHERE productcode = 'seaidftby'
ORDER BY 1
--IS NOT NULL-- = 'Cancelled'
*/

GO


