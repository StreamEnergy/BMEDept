USE [StreamInternal]
GO

/****** Object:  View [dbo].[vPartialJanuary2010Premise]    Script Date: 08/26/2014 15:20:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Eric McCormick						This view is used in the
															W:\Wholesale Reporting\Annual Reports\FERC\Top ISTA Usage 2010-2012
															required FERC report.
															History:			01.13:  In development.
															Development Notes:	See v2012_Usage_Extract

08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[vPartialJanuary2010Premise]
AS
    SELECT  c.FEIN ,
            c.CustName ,
            SUM(nd.ConsDetQty / DATEDIFF(d , n.datefrom , n.dateto)
                * DATEDIFF(d , '01/01/2010' , n.dateto)) AS StubJanuary2010
    FROM    Stream.dbo.Customer c
    INNER JOIN Stream.dbo.Premise p ON p.CustID = c.CustID
                                       AND p.PremType = 'elec'
    INNER JOIN Stream.dbo.Address a ON a.AddrID = c.MailAddrId
    INNER JOIN Stream.dbo.Address b ON b.AddrID = p.AddrID
    INNER JOIN Stream.dbo.meter m ON m.PremID = p.PremID
    INNER JOIN Stream.dbo.Consumption n ON n.MeterID = m.MeterID
    INNER JOIN Stream.dbo.ConsumptionDetail nd ON nd.ConsID = n.ConsID
                                                  AND nd.ConsUnitID = 5
                                                  AND n.DateTo BETWEEN '2010-01-01' AND '2010-12-31'
                                                  AND n.DateFrom NOT BETWEEN '2010-01-01' AND '2010-12-31'
                                                  AND DATEDIFF(d , n.datefrom ,
                                                              n.dateto) > 0
    GROUP BY c.FEIN ,
            c.CustName







GO


