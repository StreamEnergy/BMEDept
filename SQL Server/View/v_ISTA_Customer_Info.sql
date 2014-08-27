USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_ISTA_Customer_Info]    Script Date: 08/26/2014 14:20:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
7/22/2013				Darren Williams						Initial Release [v_ISTA_Customer_Info] .
															Purpose of this view is to consistently capture 
															customer and all necessary info associated to each customer.
						   
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[v_ISTA_Customer_Info]
AS
    SELECT DISTINCT
            p.PremID ,
            p.PremNo ,
            p.PremType ,
            ldc.LDCShortName ,
            c.CustNo ,
            ca.ClientAccountNo ,
            c.FEIN ,
            c.CustType ,
            c.CustStatus ,
            c.CreateDate AS 'CustomerCreateDate' ,
            p.LDCID ,
            p.PremStatus ,
            p.StatusID ,
            p.PremDesc ,
            p.BeginServiceDate ,
            p.EndServiceDate ,
            CASE WHEN ldc.LDCShortName = 'PEPCODC' THEN 'DC'
                 ELSE m.StateAbbr
            END AS 'MarketState' ,
            a.HomePhone ,
            a.OtherPhone ,
            a.Addr1 ,
            a.Addr2 ,
            a.City ,
            a.State ,
            a.Zip
    FROM    Stream.dbo.Premise p
    LEFT JOIN Stream.dbo.Customer c ON c.CustID = p.CustID
    LEFT JOIN Stream.dbo.CustomerAdditionalInfo ca ON ca.CustID = c.CustID
    LEFT JOIN Stream.dbo.Address a ON a.AddrID = p.AddrID
    LEFT JOIN Stream.dbo.LDCLookup ldc ON p.LDCID = ldc.LDCID
    LEFT JOIN StreamInternal.dbo.Market m ON m.MarketId = ldc.MarketID
    GROUP BY p.PremID ,
            p.PremNo ,
            p.PremType ,
            ldc.LDCShortName ,
            ldc.LDCID ,
            c.CustNo ,
            ca.ClientAccountNo ,
            c.FEIN ,
            c.CustType ,
            c.CustStatus ,
            c.CreateDate ,
            p.LDCID ,
            p.PremStatus ,
            p.StatusID ,
            p.PremDesc ,
            p.BeginServiceDate ,
            p.EndServiceDate ,
            m.StateAbbr ,
            a.HomePhone ,
            a.OtherPhone ,
            a.Addr1 ,
            a.Addr2 ,
            a.City ,
            a.State ,
            a.Zip 






GO


