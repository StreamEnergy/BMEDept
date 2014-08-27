USE [StreamInternal]
GO

/****** Object:  View [dbo].[v2012_Usage_Extract]    Script Date: 08/26/2014 15:14:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Eric McCormick						This view is the basis for the 
															W:\Wholesale Reporting\Annual Reports\FERC\Top ISTA Usage 2010-2012
															required FERC report.
															Development Notes:	
															The report also uses the StreamInternal.dbo.vPartialDecember2012Premise
															and StreamInternal.dbo.vPartialjanuary2010premise views to include
															partial year data.
															The annual generation of this report may be performed by ISTA, but
															historically has been validated by Stream. (Sarah Tang)					  
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[v2012_Usage_Extract]
AS
    SELECT  
		--p.PremNo,
		--c.CustID,
            c.FEIN ,
            C.CustName , 
		--a.Addr1 as MailAddr1,
		--a.Addr2 as MailAddr2,
		--a.City  as MailCity,
		--a.State as MailState,
		--a.Zip	as MailZip,
            b.State AS ServiceState ,
--		m.MeterID as MeterID,
            SUM(nd.ConsDetQty) AS Consumption
    FROM    Stream.dbo.Customer c
    INNER JOIN Stream.dbo.Premise p ON p.CustID = c.CustID
                                       AND p.PremType = 'elec'
    INNER JOIN Stream.dbo.Address a ON a.AddrID = c.MailAddrId
    INNER JOIN Stream.dbo.Address b ON b.AddrID = p.AddrID
    INNER JOIN Stream.dbo.meter m ON m.PremID = p.PremID
    INNER JOIN Stream.dbo.Consumption n ON n.MeterID = m.MeterID
                                           AND ( n.DateFrom BETWEEN '2010-01-01' AND '2012-12-31'
                                                 OR n.DateTo BETWEEN '2010-01-01' AND '2012-12-31'
                                               )
    INNER JOIN Stream.dbo.ConsumptionDetail nd ON nd.ConsID = n.ConsID
                                                  AND nd.ConsUnitID = 5
    GROUP BY
		--p.PremNo,
		--c.CustID,
            c.FEIN ,
            C.CustName , 
		--a.Addr1,
		--a.Addr2,
		--a.City,
		--a.State,
		--a.Zip,
            b.State
--		m.MeterID


	    


















GO


