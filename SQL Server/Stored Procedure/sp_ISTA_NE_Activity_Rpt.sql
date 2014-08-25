USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ISTA_NE_Activity_Rpt]    Script Date: 08/25/2014 12:21:01 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
9/17/2013			Darren Williams				This SP is for the ISTA NE Activity Report. 
8/26/2013			Darren Williams				Initial Release [sp_ISTA_NE_Activity_Rpt] .
												Purpose of this SP is for the NE Bucket Report. 
												
4/10/2014			Darren Williams				Ticket #465 - Incorrect data on activity prt  (max/min) 
08/15/2014			Jide Akintoye				Format Stored Procedure




**********************************************************************************************/



CREATE PROCEDURE [dbo].[sp_ISTA_NE_Activity_Rpt]
AS
    BEGIN

        DECLARE @Today DATETIME ,
            @BeginDate DATETIME ,
            @EndDate DATETIME

        SET @Today = GETDATE()
        SET @BeginDate = '1/1/07'
        SET @EndDate = '12/31/99'

        SELECT  rd.RateDetID ,
                rt.RolloverFlag ,
                cai.ClientAccountNo ,
                c.FirstName ,
                c.LastName ,
                a.Addr1 ,
                a.Addr2 ,
                a.City ,
                a.State ,
                a.Zip ,
                a.HomePhone ,
                a.Email ,
                ec.Last4SSN ,
                c.CustNo ,
                c.CustType ,
                c.CustStatus AS 'Customer Status' ,
                c.CreateDate ,
                l.LDCName ,
                l.LDCID ,
                CASE WHEN l.LDCName = 'Potomac Electric DC'
                          AND m.StateAbbr = 'MD' THEN 'DC'
                     ELSE m.StateAbbr
                END AS MarketState ,
	--m.StateAbbr as MarketState,
                p.PremNo ,
                p.PremID ,
                p.PremType ,
                ps.PremiseStatusID ,
                ps.Status AS 'Premise Status' ,
                pt.Description AS plantype ,
                rd.EffectiveDate ,
                ISNULL(rd.ExpirationDate , GETDATE()) AS ExpirationDate ,
                ec.QCDateTimeStamp ,
                p.BeginServiceDate ,
                p.EndServiceDate ,
                rt.SoldDate ,
                MAX(rt4.SoldDate) AS PreviousSoldDate ,  --added
                rt2.SoldDate AS FutureSoldDate ,
                rt.CreatedDate AS SwitchDate ,
                rt2.CreatedDate AS FutureSwitchDate ,  --added
                MAX(rt4.CreatedDate) AS PreviousSwitchDate ,
                rt.UserID ,
                su.FirstName AS UserFirstName ,
                su.LastName AS UserLastName ,
                ia.AssociateNumber ,
                ia.AssociateName ,
                ia.AssociateEmail ,
                ia.AssociatePhone ,
                rt2.RateTransitionID AS FutureRateTransitionID ,
                MAX(rt4.RateTransitionID) AS PreviousRateTransitionID ,  --added
                rd2.RateDetID AS FutureRateDetID ,
                MAX(rd4.RateDetID) AS PreviousRateDetID ,  --added
                rd.RateAmt ,
                rir.IndexRate ,
                rir2.RateIndexTypeID AS FutureRateIndexTypeID ,
                MAX(rir4.RateIndexTypeID) AS PreviousRateIndexTypeID ,  --added
                rit2.RateIndexType AS FutureRateIndexType ,
                MIN(rit4.RateIndexType) AS PreviousRateIndexType ,  --added
                rir.RateIndexTypeID AS CurrentRateIndexTypeID ,
                rit.RateIndexType AS CurrentRateIndexType ,
                at.ActiveRateDetID ,
                at.ActiveProductCode ,
                at.ActiveProductName ,
                CASE at.ActivePlanType
                  WHEN 1 THEN 'Fixed'
                  WHEN 2 THEN 'Variable'
                  ELSE NULL
                END AS 'ActivePlanType' ,	
	--at.ActivePlanType,
                at.ActivePlanTypeDesc ,
                at.ActiveRateIndexType ,
                at.ActiveRateAmt ,
                at.ActiveBeginServiceDate ,
                at.ActiveEffectiveDate ,
                at.ActiveExpirationDate ,
                MIN(pr4.ProductName) AS 'Previous Product Name' ,  --added
                MIN(pr4.Description) AS 'Previous Product Description' ,   --added
                MIN(pr4.ProductCode) AS 'Previous Product Code' , --added
                MAX(rt4.SoldDate) AS 'Previous Sold Date' ,--added
                CASE MAX(pr4.PlanType)   --added
                  WHEN 1 THEN 'Fixed'
                  WHEN 2 THEN 'Variable'
                  ELSE NULL
                END AS 'Previous Plan Type' ,
	--pr4.PlanType AS 'Previous Plan Type',
                pr.PriceDescription AS 'Previous Price Description' ,
                pr.ProductName AS 'Current Product Name' ,
                pr.Description AS 'Current Product Description' ,
                pr.ProductCode AS 'Current Product Code' ,
                CASE pr.PlanType
                  WHEN 1 THEN 'Fixed'
                  WHEN 2 THEN 'Variable'
                  ELSE NULL
                END AS 'Current Plan Type' ,
	--pr.PlanType AS 'Current Plan Type',
                pr.PriceDescription AS 'Current Price Description' ,
                CASE WHEN ( MAX(pr4.PlanType) = 1 )
                          AND ( pr.PlanType = 1 ) THEN 'Renewal'  --added
                     WHEN ( pr.PlanType = 1 )
                          AND ( MAX(pr4.PlanType) = 2 ) THEN 'Conversion'
                     WHEN ( pr.PlanType = 1 )
                          AND ( MAX(pr4.PlanType) IS NULL ) THEN 'New'
                     WHEN ( pr.PlanType = 2 )
                          AND ( MAX(pr4.PlanType) IS NULL ) THEN 'New'
                     WHEN ( pr.PlanType = 2 )
                          AND ( MAX(pr4.PlanType) = 2 )
                          AND ( rt.RolloverFlag <> 0 )
                     THEN 'Rollover (MTM to MTM)'
                     WHEN ( pr.PlanType = 2 )
                          AND ( MAX(pr4.PlanType) = 1 )
                          AND ( rt.RolloverFlag <> 0 )
                     THEN 'Rollover (Term to MTM)'
                     ELSE 'Researching'
                END AS ContractType ,
                pr2.Description AS 'Future Product Description' ,
                pr2.ProductName AS 'Future Product Name' ,
                pr2.ProductCode AS 'Future Product Code' ,
                pr2.PriceDescription AS 'Future Price Description' ,
                MAX(rd2.RateAmt) AS 'Future RateAmt' ,
                MAX(rir2.IndexRate) AS 'Future Index Rate' ,
                pr2.BeginDate AS 'Future Date' ,  --added
                pr3.Description AS 'Rollover Product Description' ,
                pr3.ProductName AS 'Rollover Product Name' ,
                pr3.ProductCode AS 'Rollover Product Code' ,
                pr3.PriceDescription AS 'Rollover Price Description' ,
                CASE cai.BillingTypeId
                  WHEN 1 THEN 'Suppliier Consolidated'
                  WHEN 2 THEN 'Bill Ready'
                  WHEN 3 THEN 'Rate Ready'
                  WHEN 4 THEN 'Dual'
                  ELSE NULL
                END AS 'Billing Type' ,
                CASE WHEN GETDATE() BETWEEN rd.EffectiveDate
                                    AND     ISNULL(rd.ExpirationDate ,
                                                   '1/1/2099')
                          AND rd.Active = 1 THEN 'Active'
                     WHEN GETDATE() < rd.EffectiveDate
                          AND rd.Active = 1 THEN 'Pending'
                END AS ContractStatus ,
                rt.EndDate
	--into #sort_contract
        FROM    Stream.dbo.Customer c
        JOIN    Stream.dbo.CustomerAdditionalInfo cai ON cai.CustID = c.CustID
        JOIN    Stream.dbo.Address a ON a.AddrID = c.MailAddrId
        JOIN    Stream.dbo.Premise p ON p.CustID = c.CustID
        JOIN    Stream.dbo.LDCLookup l ON l.LDCID = p.LDCID
        JOIN    StreamInternal.dbo.Market m ON m.MarketId = l.MarketID
        JOIN    Stream.dbo.PremiseStatus ps ON ps.PremiseStatusID = p.StatusID
        JOIN    Stream.dbo.RateDetail rd ON rd.RateID = c.RateID
                                            AND rd.Active = 1
                                            AND rd.RateTypeID IN ( 1 , 2 , 7 ,
                                                              8 , 9 , 1001 ,
                                                              1002 , 1004 ,
                                                              3001 , 3002 )
                                            AND rd.ExpirationDate > rd.EffectiveDate
        LEFT JOIN Stream.dbo.RateIndexRange rir ON rir.RateIndexTypeID = rd.FixedCapRate
                                                   AND @Today BETWEEN rir.DateFrom AND rir.DateTo
        LEFT JOIN Stream.dbo.RateIndexType rit ON rit.RateIndexTypeID = rd.FixedCapRate
        JOIN    Stream.dbo.RateTransition rt ON rt.RateTransitionID = rd.RateTransitionId
        JOIN    Stream.dbo.SecUser su ON su.UserID = rt.UserID
        JOIN    Stream.dbo.Product pr ON pr.RateID = rt.RateID
        LEFT JOIN Stream.dbo.EnrollCustomer ec ON ec.CsrCustID = c.CustID
        LEFT JOIN Stream.dbo.RateTransition rt2 ON rt2.CustID = c.CustID
                                                   AND rt2.SoldDate >= rt.SoldDate
                                                   AND rt2.RateTransitionID > rt.RateTransitionID
                                                   AND rt2.RolloverFlag = 0
                                                   AND rt2.SwitchDate < rt2.EndDate
        LEFT JOIN Stream.dbo.RateTransition rt4 ON rt4.CustID = c.CustID
                                                   AND rt4.SoldDate <= rt.SoldDate
                                                   AND rt4.RateTransitionID < rt.RateTransitionID
                                                   AND rt4.SwitchDate < rt4.EndDate
        LEFT JOIN Stream.dbo.Product pr4 ON pr4.RateID = rt4.RateID
        LEFT JOIN Stream.dbo.RateDetail rd4 ON rd4.RateTransitionId = rt4.RateTransitionID
                                               AND rd4.ExpirationDate > rd4.EffectiveDate
        LEFT JOIN Stream.dbo.RateIndexRange rir4 ON rir4.RateIndexTypeID = rd4.FixedCapRate
                                                    AND rt4.SoldDate BETWEEN rir4.DateFrom
                                                              AND
                                                              rir4.DateTo
        LEFT JOIN Stream.dbo.RateIndexType rit4 ON rit4.RateIndexTypeID = rd4.FixedCapRate
        LEFT JOIN Stream.dbo.Product pr2 ON pr2.RateID = rt2.RateID
                                            AND pr2.RolloverProductId IS NOT NULL
        LEFT JOIN Stream.dbo.Product pr3 ON pr3.ProductID = pr.RolloverProductID
        LEFT JOIN Stream.dbo.RateDetail rd2 ON rd2.RateTransitionId = rt2.RateTransitionID
                                               AND rd2.ExpirationDate > rd2.EffectiveDate
        LEFT JOIN Stream.dbo.RateIndexRange rir2 ON rir2.RateIndexTypeID = rd2.FixedCapRate
                                                    AND rt2.SoldDate BETWEEN rir2.DateFrom
                                                              AND
                                                              rir2.DateTo --> MarkC
        LEFT JOIN Stream.dbo.RateIndexType rit2 ON rit2.RateIndexTypeID = rd2.FixedCapRate
        LEFT JOIN Stream.dbo.RateDetail rd3 ON rd3.RateID = pr3.RateID
        LEFT JOIN Stream.dbo.RateIndexRange rir3 ON rir3.RateIndexTypeID = rd3.FixedCapRate
                                                    AND @Today BETWEEN rir3.DateFrom AND rir3.DateTo
        LEFT JOIN Stream.dbo.RateIndexType rit3 ON rit3.RateIndexTypeID = rd3.FixedCapRate
        LEFT JOIN Stream.dbo.PlanType pt ON pt.PlanTypeID = pr.PlanType
        LEFT JOIN ( SELECT DISTINCT
                            cc.CustNo ,
                            cc.RateDetID AS ActiveRateDetID ,
                            cc.ProductCode AS ActiveProductCode ,
                            cc.ProductName AS ActiveProductName ,
                            cc.PlanType AS ActivePlanType ,
                            cc.PlanTypeDesc AS ActivePlanTypeDesc ,
                            cc.RateIndexType AS ActiveRateIndexType ,
                            cc.RateAmt AS ActiveRateAmt ,
                            cc.BeginServiceDate AS ActiveBeginServiceDate ,
                            cc.EffectiveDate AS ActiveEffectiveDate ,
                            cc.ExpirationDate AS ActiveExpirationDate
                    FROM    StreamInternal.dbo.v_Contract cc
                    WHERE   GETDATE() BETWEEN cc.EffectiveDate
                                      AND     ISNULL(cc.ExpirationDate ,
                                                     '1/1/2099')
                            AND cc.Active = 1
                  ) at ON at.CustNo = c.CustNo
        LEFT JOIN ( SELECT  c.[Customer Number] ,
                            i.AssociateNumber ,
                            i.AssociateName ,
                            i.AssociateEmail ,
                            i.AssociatePhone
                    FROM    [Eagle].[dbo].[tblCustomers] c
                    JOIN    [Eagle].[dbo].[tblIgniteAssociates] i ON i.AssociateNumber = c.[Sponsor Number]
                  ) ia ON ia.[Customer Number] = cai.ClientAccountNo
        WHERE   1 = 1
                AND pt.DESCRIPTION <> 'Variable'
                AND ps.PremiseStatusID IN ( 5 , 6 , 7 , 8 , 9 , 10 , 11 )
	--rt.EndDate BETWEEN @BeginDate AND @EndDate
	--and cai.ClientAccountNo = 'C1102343'  --C1829308
                AND pr4.PlanType IS NOT NULL
	--and c.custno = '3000007692'-- 3000017275 in ('3000241436','3000053911')
        GROUP BY rd.RateDetID ,
                rt.SoldDate ,
                rt2.SoldDate ,
                rt2.RateTransitionID ,
                rd2.RateDetID ,
                pt.Description ,
                rd.EffectiveDate ,
                rd.ExpirationDate ,
                rir2.RateIndexTypeID ,
                c.CustNo ,
                c.FirstName ,
                c.LastName ,
                c.CustType ,
                c.CreateDate ,
                a.HomePhone ,
                a.Email ,
                l.LDCName ,
                a.Addr1 ,
                a.Addr2 ,
                a.City ,
                a.State ,
                a.Zip ,
                ps.Status ,
                c.CustStatus ,
                ec.QCDateTimeStamp ,
                p.BeginServiceDate ,
                p.EndServiceDate ,
                ec.Last4SSN ,
                rd.RateAmt ,
                rir.IndexRate ,
                p.PremNo ,
                p.PremID ,
                p.PremType ,
                pr.Description ,
                pr.ProductName ,
                pr.ProductCode ,
                pr.PriceDescription ,
                pr2.Description ,
                pr2.ProductName ,
                pr2.ProductCode ,
                pr2.PriceDescription ,
                rd2.RateAmt ,
                pr2.BeginDate ,
                cai.BillingTypeId ,
                rt.EndDate ,
                rd.Active ,
                at.ActiveRateDetID ,
                at.ActiveProductCode ,
                at.ActiveProductName ,
                at.ActivePlanType ,
                at.ActivePlanTypeDesc ,
                at.ActiveRateIndexType ,
                at.ActiveRateAmt ,
                at.ActiveBeginServiceDate ,
                at.ActiveExpirationDate ,
                at.ActiveEffectiveDate ,
                rit.RateIndexType ,
                rit2.RateIndexType ,
                l.LDCID ,
                cai.ClientAccountNo ,
                rir.RateIndexTypeID ,
                rit.RateIndexType ,
                m.StateAbbr ,
                rir2.RateIndexTypeID ,
                rit2.RateIndexType ,
                rt.CreatedDate ,
                rt2.CreatedDate ,
                rt.UserID ,
                su.FirstName ,
                su.LastName ,
                rt.RolloverFlag ,
                ia.AssociateNumber ,
                ia.AssociateName ,
                ia.AssociateEmail ,
                ia.AssociatePhone ,
                ps.PremiseStatusID ,
                pr.PlanType ,
                pr2.PlanType ,
                pr3.DESCRIPTION ,
                pr3.ProductName ,
                pr3.ProductCode ,
                pr3.PriceDescription 	
	--rir4.RateIndexTypeID , --rt4.RateTransitionID ,rd4.RateDetID ,rit4.RateIndexType,pr4.ProductName,pr4.Description,
	-- rt4.SoldDate,rt4.CreatedDate,pr4.PlanType,
	--pr4.PlanType ,pr4.ProductCode 
        ORDER BY rt.SoldDate ,
                rt2.SoldDate



	--==================================
	-- final result for bucket report
	--==================================
        SELECT  cc.*
        INTO    #bucket
        FROM    ( SELECT    c.RateDetID ,
                            MAX(c.PreviousSoldDate) AS SoldDate4
                  FROM      #sort_contract c
                  GROUP BY  c.RateDetID
                ) ss
        LEFT JOIN #sort_contract cc ON ss.RateDetID = cc.RateDetID
                                       AND ISNULL(ss.SoldDate4 , '12/31/2999') = ISNULL(cc.PreviousSoldDate ,
                                                              '12/31/2999')
        WHERE   cc.RateDetID IS NOT NULL
        ORDER BY cc.RateDetID ,
                cc.CustNo
	
        DROP TABLE #sort_contract
	
	-- insert final data
        SELECT  *
        FROM    ( SELECT    b.*
                  FROM      #bucket b
                  WHERE     b.RateDetID IN ( SELECT ba.RateDetID
                                             FROM   #bucket ba
                                             GROUP BY ba.RateDetID
                                             HAVING COUNT(*) <= 1 )
                  UNION ALL
                  SELECT    b.*
                  FROM      #bucket b
                  WHERE     b.[Premise Status] <> 'Inactive'
                            AND b.RateDetID IN (
                            SELECT  bb.RateDetID
                            FROM    #bucket bb
                            WHERE   b.[Premise Status] <> 'Inactive'
                            GROUP BY bb.RateDetID
                            HAVING  COUNT(*) > 1 )
                  UNION ALL
                  SELECT    b.*
                  FROM      #bucket b
                  INNER JOIN ( SELECT   bc.RateDetID ,
                                        MAX(bc.EndServiceDate) AS EndServiceDate
                               FROM     #bucket bc
                               WHERE    bc.[Premise Status] = 'Inactive'
                               GROUP BY bc.RateDetID
                               HAVING   COUNT(*) > 1
                             ) b1 ON b1.RateDetID = b.RateDetID
                                     AND ISNULL(b1.EndServiceDate ,
                                                '12/31/2999') = ISNULL(b.EndServiceDate ,
                                                              '12/31/2999')
                  WHERE     b.[Premise Status] = 'Inactive'
                ) fb
        ORDER BY fb.RateDetID
	
        DROP TABLE #bucket

--Test
--select Distinct 
--			cc.CustNo,
--			cc.RateDetID as ActiveRateDetID,
--			cc.ProductCode as ActiveProductCode,
--			cc.ProductName as ActiveProductName,
--			cc.PlanTypeDesc as ActivePlanTypeDesc,
--			cc.RateIndexType as ActiveRateIndexType
--			from StreamInternal.dbo.v_Contract cc
--			Inner Join (	
--			select 	distinct
--			 c.CustNo, 
--			Max(rd.RateDetID) as RateDetID
--			from 
--			stream.dbo.Customer c 
--			left join stream.dbo.Premise p on p.CustID = c.CustID
--			/*left*/ join stream.dbo.RateDetail rd on rd.RateID = c.RateID --and rd.Active = 1 and isnull(rd.ExpirationDate, '1/1/2099') >= GETDATE()
--			left join stream.dbo.RateIndexType rit on rit.RateIndexTypeID = rd.FixedCapRate
--			left join stream.dbo.RateTransition rt on rd.RateTransitionId = rt.RateTransitionID/*rt.CustID = c.CustID*/ --and isnull(rt.EndDate,'1/1/2099') >= GETDATE() and rt.StatusID in (1,2) --pending or active
--			left join stream.dbo.Product d on d.RateID = rt.RateID
--			left join stream.dbo.RateIndexRange rir on rir.RateIndexTypeID = rd.FixedCapRate and GETDATE() between rir.DateFrom and rir.DateTo -- there are multiple prices, you need to specify for which date
--			left join stream.dbo.LDCLookup l on l.LDCID = p.LDCID
--			left join stream.dbo.PremiseStatus ps on p.StatusID = ps.PremiseStatusID
--			left join stream.dbo.terms t on t.termsid = d.termsid
--			left join stream.dbo.PlanType pt on pt.PlanTypeID = d.PlanType
--			group by c.CustNo) x on cc.RateDetID = x.RateDetID

    END


























GO


