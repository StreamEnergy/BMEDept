USE [StreamInternal]
GO

/****** Object:  View [dbo].[vPA_Usage_Extract]    Script Date: 08/26/2014 15:19:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description


08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/


CREATE VIEW [dbo].[vPA_Usage_Extract]
AS
    SELECT  p.PremNo ,
            p.PremID ,
            p.PremDesc ,
            c.CustID ,
            c.FEIN ,
            c.CustNo ,
            C.CustName ,
            c.FirstName ,
            c.LastName ,
            c.MailAddrId ,
            c.MailToSiteAddress ,
            a.AddrID ,
            a.Addr1 AS MailAddr1 ,
            a.Addr2 AS MailAddr2 ,
            a.City AS MailCity ,
            a.State AS MailState ,
            a.Zip AS MailZip ,
            b.Addr1 AS ServiceAddr1 ,
            b.Addr2 AS ServiceAddr2 ,
            b.City AS ServiceCity ,
            b.State AS ServiceState ,
            b.Zip AS ServiceZip ,
            SUM(nd.ConsDetQty) AS TotalConsumption
    FROM    Stream.dbo.Customer c
    INNER JOIN Stream.dbo.Premise p ON p.CustID = c.CustID
    INNER JOIN Stream.dbo.Address a ON a.AddrID = c.MailAddrId
    INNER JOIN stream.dbo.Address b ON b.AddrID = p.AddrID
    INNER JOIN Stream.dbo.meter m ON m.PremID = p.PremID
    INNER JOIN Stream.dbo.Consumption n ON n.MeterID = m.MeterID
    INNER JOIN Stream.dbo.ConsumptionDetail nd ON nd.ConsID = n.ConsID
                                                  AND nd.ConsUnitID = 5
    GROUP BY p.PremNo ,
            p.PremID ,
            p.PremDesc ,
            c.CustID ,
            c.FEIN ,
            c.CustNo ,
            C.CustName ,
            c.FirstName ,
            c.LastName ,
            c.MailAddrId ,
            c.MailToSiteAddress ,
            a.AddrID ,
            a.Addr1 ,
            a.Addr2 ,
            a.City ,
            a.State ,
            a.Zip ,
            b.Addr1 ,
            b.Addr2 ,
            b.City ,
            b.State ,
            b.zip
	    







GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Used for annual FERC reporting.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'vPA_Usage_Extract'
GO


