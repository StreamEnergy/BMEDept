USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_ProductCatalog]    Script Date: 08/26/2014 15:13:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
5/9/2014				MarkC								Initial Release [v_ProductCatalog].
															  
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/


CREATE VIEW [dbo].[v_ProductCatalog]
AS
    SELECT  p.ProductID ,
            p.ActiveEnrollmentFlag ,
            p.CustType ,
            p.ServiceType ,
            p.ActiveFlag ,
            p.RolloverProductId ,
            pz.Description AS Zone ,
            rr.RateIndexRangeID ,
            p.ProductCode ,
            CASE WHEN l.LDCShortName = 'PEPCODC' THEN 'DC'
                 ELSE m.StateAbbr
            END AS State ,
            l.LDCShortName ,
            p.PlanType ,
            pt.Description AS PlanTypeDesc ,
            t.Months ,
            rr.DateFrom ,
            rr.DateTo ,
            rr.IndexRate ,
            rit.RateIndexType
    FROM    stream.dbo.product p
    LEFT JOIN stream.dbo.ProductZone pz ON p.ProductZoneID = pz.ProductZoneId
    LEFT JOIN stream.dbo.LDCLookup l ON l.LDCID = p.LDCCode
    LEFT JOIN StreamInternal.dbo.Market m ON m.MarketId = l.MarketID
--left join stream.dbo.marketname m on m.MarketId = l.MarketID
    LEFT JOIN stream.dbo.RateDetail rd ON p.RateID = rd.RateID
    LEFT JOIN stream.dbo.Rateindexrange rr ON rr.RateIndexTypeID = rd.FixedCapRate
    LEFT JOIN stream.dbo.RateIndexType rit ON rit.RateIndexTypeID = rd.FixedCapRate
    LEFT JOIN stream.dbo.PlanType pt ON pt.PlanTypeID = p.PlanType
    LEFT JOIN stream.dbo.Terms t ON p.TermsId = t.TermsID

       





GO


