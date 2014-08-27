USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Contract]    Script Date: 08/26/2014 13:30:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
7/14/2013				MarkC							Initial Release v_contract.
														(1) View of Ista Contracts at premise level. Do not add meter level data to this view. This will cause data duplications.
														(2) RateDetID is the contract key. However, RateDetID is not unique in the view due to a contract could span over multiple premises (PremID) over time.
														(3) RateAmt => use this column to pull customer's contract Fixed Rate
														(4) IndexRate => use this column to pull customer's current Variable Rate
7/23/2013				MarkC							Added the following columns:
														(1) PlanLength 
														(2) ProductID 
														(3) PlanTypeDesc
2/12/2014				Steve Nelson					Add PriceDescription column.
2/26/2014				MarkC							Strip off timestamp using [cast(GETDATE() as DATE)] for ContractStatus
08/26/2014 				Jide Akintoye					Formatted View



**********************************************************************************************/


CREATE VIEW [dbo].[v_Contract]
AS
    SELECT DISTINCT
            c.CustID ,
            c.CustNo ,
            c.CustType ,
            p.PremNo ,
            p.PremID ,
            p.BeginServiceDate ,
            p.EndServiceDate ,
            P.CreateDate ,
            ps.status AS PremiseStatus ,
            l.LDCID ,
            l.LDCName ,
            rd.RateDetID ,
            rd.RateID ,
            rd.RateAmt , --this is FR, mtm get from rateindexrange tbl
            rir.IndexRate , -- this is mtm rate
            rd.EffectiveDate ,
            rd.ExpirationDate ,
            rd.Active , -- 
            d.ProductID ,
            d.ProductCode ,
            d.ProductName ,
            d.PriceDescription ,
            rit.RateIndexType ,
            rt.RateTransitionID ,  -- added to view 11/5/2013
            rt.SoldDate ,			-- added to view 11/5/2013
            d.PlanType ,
            pt.Description AS PlanTypeDesc ,
            CASE WHEN t.Months IS NULL
                      AND pt.Description = 'Variable' THEN 1
                 ELSE t.Months
            END AS PlanLength ,
            p.LastModifiedDate AS LastUpdateDate ,
            p.StatusID ,
            CASE WHEN CAST(GETDATE() AS DATE) BETWEEN rd.EffectiveDate
                                              AND     ISNULL(rd.ExpirationDate ,
                                                             '1/1/2099')
                      AND rd.Active = 1 THEN 'Active'
                 WHEN GETDATE() < rd.EffectiveDate
                      AND rd.Active = 1 THEN 'Pending'
            END AS ContractStatus
    FROM    stream.dbo.Customer c
    LEFT JOIN stream.dbo.Premise p ON p.CustID = c.CustID
/*left*/
    JOIN    stream.dbo.RateDetail rd ON rd.RateID = c.RateID --and rd.Active = 1 and isnull(rd.ExpirationDate, '1/1/2099') >= GETDATE()
    LEFT JOIN stream.dbo.RateIndexType rit ON rit.RateIndexTypeID = rd.FixedCapRate
    LEFT JOIN stream.dbo.RateTransition rt ON rd.RateTransitionId = rt.RateTransitionID/*rt.CustID = c.CustID*/ --and isnull(rt.EndDate,'1/1/2099') >= GETDATE() and rt.StatusID in (1,2) --pending or active
    LEFT JOIN stream.dbo.Product d ON d.RateID = rt.RateID
    LEFT JOIN stream.dbo.RateIndexRange rir ON rir.RateIndexTypeID = rd.FixedCapRate
                                               AND GETDATE() BETWEEN rir.DateFrom AND rir.DateTo -- there are multiple prices, you need to specify for which date
    LEFT JOIN stream.dbo.LDCLookup l ON l.LDCID = p.LDCID
    LEFT JOIN stream.dbo.PremiseStatus ps ON p.StatusID = ps.PremiseStatusID
    LEFT JOIN stream.dbo.terms t ON t.termsid = d.termsid
    LEFT JOIN stream.dbo.PlanType pt ON pt.PlanTypeID = d.PlanType







GO


