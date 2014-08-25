USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ISTA_NE_Bucket_Rpt]    Script Date: 08/25/2014 12:21:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
8/26/2013			Darren Williams				This SP is for the ISTA NE Bucket Report. 
8/26/2013			Darren Williams				Initial Release [sp_ISTA_NE_Bucket_Rpt] .
												Purpose of this SP is for the NE Bucket Report. 
08/15/2014			Jide Akintoye				Format Stored Procedure





**********************************************************************************************/




CREATE PROCEDURE [dbo].[sp_ISTA_NE_Bucket_Rpt]
AS
    BEGIN

        DECLARE @Today DATETIME ,
            @BeginDate DATETIME ,
            @EndDate DATETIME

        SET @Today = GETDATE()
        SET @BeginDate = '1/1/07'
        SET @EndDate = '12/31/99'

        SELECT  rd.RateDetID ,
                rt.SoldDate ,
                rt2.SoldDate AS SoldDate2 ,
                rt2.RateTransitionID ,
                rd2.RateDetID AS RateDetID_2 ,
                rd3.RateDetID AS RateDetID_3 ,
                pt.Description AS plantype ,
                rd.EffectiveDate ,
                ISNULL(rd.ExpirationDate , GETDATE()) AS ExpirationDate ,
	--rir2.RateIndexTypeID as FutureRateIndexTypeID,
                rit2.RateIndexType AS FutureRateIndexType ,
	--rir.RateIndexTypeID as CurrentRateIndexTypeID,
                rit.RateIndexType AS CurrentRateIndexType ,
	--rir3.RateIndexTypeID as RolloverRateIndexTypeID,
                rit3.RateIndexType AS RolloverRateIndexType ,
                c.CustNo ,
                cai.ClientAccountNo ,
                c.FirstName ,
                c.LastName ,
                c.CustType ,
                c.CreateDate ,
                a.HomePhone ,
                a.Email ,
                l.LDCName ,
                m.StateAbbr AS MarketState ,
                a.Addr1 ,
                a.Addr2 ,
                a.City ,
                a.State ,
                a.Zip ,
                ps.Status AS 'Premise Status' ,
                c.CustStatus AS 'Customer Status' ,
                ec.QCDateTimeStamp ,
                p.BeginServiceDate ,
                p.EndServiceDate ,
                ec.Last4SSN ,
                ia.AssociateNumber ,
                ia.AssociateName ,
                ia.AssociateEmail ,
                ia.AssociatePhone ,
                rd.RateAmt ,
                rir.IndexRate ,
                p.PremNo ,
                p.PremID ,
                p.PremType ,
                pr.Description AS 'Current Product Description' ,
                pr.ProductName AS 'Current Product Name' ,
                pr.ProductCode AS 'Current Product Code' ,
                pr.PriceDescription AS 'Current Price Description' ,
                pr2.Description AS 'Future Product Description' ,
                pr2.ProductName AS 'Future Product Name' ,
                pr2.ProductCode AS 'Future Product Code' ,
                pr2.PriceDescription AS 'Future Price Description' ,
                MAX(rd2.RateAmt) AS 'Future RateAmt' ,
                MAX(rir2.IndexRate) AS 'Future Index Rate' ,
                pr2.BeginDate AS 'Future Date' ,
                pr3.Description AS 'Rollover Product Description' ,
                pr3.ProductName AS 'Rollover Product Name' ,
                pr3.ProductCode AS 'Rollover Product Code' ,
                pr3.PriceDescription AS 'Rollover Price Description' ,
                MAX(rd3.RateAmt) AS 'Rollover RateAmt' ,
                MAX(rir3.IndexRate) AS 'Rolloever Index Rate' ,
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
                rt.EndDate ,
                at.ActiveRateDetID ,
                at.ActiveProductCode ,
                at.ActiveProductName ,
                at.ActivePlanTypeDesc ,
                at.ActiveRateIndexType ,
                at.ActiveRateAmt ,
                at.ActiveBeginServiceDate ,
                at.ActiveExpirationDate
        INTO    #sort_contract
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
	-- AND @Today BETWEEN rd.EffectiveDate AND ISNULL(rd.ExpirationDate, getdate())
        LEFT JOIN Stream.dbo.RateIndexRange rir ON rir.RateIndexTypeID = rd.FixedCapRate
                                                   AND @Today BETWEEN rir.DateFrom AND rir.DateTo
        LEFT JOIN Stream.dbo.RateIndexType rit ON rit.RateIndexTypeID = rd.FixedCapRate
        JOIN    Stream.dbo.RateTransition rt ON rt.RateTransitionID = rd.RateTransitionId
        JOIN    Stream.dbo.Product pr ON pr.RateID = rt.RateID
        LEFT JOIN Stream.dbo.EnrollCustomer ec ON ec.CsrCustID = c.CustID
        LEFT JOIN Stream.dbo.RateTransition rt2 ON rt2.CustID = c.CustID
                                                   AND rt2.SoldDate >= rt.SoldDate
                                                   AND rt2.RateTransitionID > rt.RateTransitionID
                                                   AND rt2.RolloverFlag = 0
                                                   AND rt2.SwitchDate < rt2.EndDate
        LEFT JOIN Stream.dbo.Product pr2 ON pr2.RateID = rt2.RateID
                                            AND pr2.RolloverProductId IS NOT NULL
        LEFT JOIN Stream.dbo.Product pr3 ON pr3.ProductID = pr.RolloverProductID
        LEFT JOIN Stream.dbo.RateDetail rd2 ON rd2.RateTransitionId = rt2.RateTransitionID
                                               AND rd2.ExpirationDate > rd2.EffectiveDate
        LEFT JOIN Stream.dbo.RateIndexRange rir2 ON rir2.RateIndexTypeID = rd2.FixedCapRate
		--AND rt2.SoldDate BETWEEN rd.EffectiveDate AND ISNULL(rd.ExpirationDate, getdate())
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
                            cc.PlanTypeDesc AS ActivePlanTypeDesc ,
                            cc.RateIndexType AS ActiveRateIndexType ,
                            cc.RateAmt AS ActiveRateAmt ,
                            cc.BeginServiceDate AS ActiveBeginServiceDate ,
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
        WHERE   1 = 1 --and
                AND pt.Description <> 'Variable'
                AND ps.PremiseStatusID IN ( 5 , 6 , 7 , 8 , 9 , 10 , 11 )
	--rt.EndDate BETWEEN @BeginDate AND @EndDate
	--and c.custno = '3000073160'--in ('3000241436','3000053911')
        GROUP BY rd.RateDetID ,
                rt.SoldDate ,
                rt2.SoldDate ,
                rt2.RateTransitionID ,
                rd2.RateDetID ,
                rd3.RateDetID ,
                pt.Description ,
                rd.EffectiveDate ,
                rd.ExpirationDate ,
                rir2.RateIndexTypeID ,
                c.CustNo ,
                cai.ClientAccountNo ,
                c.FirstName ,
                c.LastName ,
                c.CustType ,
                c.CreateDate ,
                a.HomePhone ,
                a.Email ,
                l.LDCName ,
                m.StateAbbr ,
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
                ia.AssociateNumber ,
                ia.AssociateName ,
                ia.AssociateEmail ,
                ia.AssociatePhone ,
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
                pr3.Description ,
                pr3.ProductName ,
                pr3.ProductCode ,
                pr3.PriceDescription ,
                cai.BillingTypeId ,
                rt.EndDate ,
                rd.Active ,
                AT.ActiveRateDetID ,
                AT.ActiveProductCode ,
                AT.ActiveProductName ,
                AT.ActivePlanTypeDesc ,
                AT.ActiveRateIndexType ,
                AT.ActiveRateAmt ,
                AT.ActiveBeginServiceDate ,
                AT.ActiveExpirationDate ,
                rit.RateIndexType ,
                rit2.RateIndexType ,
                rit3.RateIndexType
        ORDER BY rt.SoldDate ,
                rt2.SoldDate

	--==================================
	-- final result for bucket report
	--==================================
        SELECT  cc.*
        INTO    #bucket
        FROM    ( SELECT    c.RateDetID ,
                            MIN(c.SoldDate2) AS SoldDate2
                  FROM      #sort_contract c
                  GROUP BY  c.RateDetID
                ) ss
        LEFT JOIN #sort_contract cc ON ss.RateDetID = cc.RateDetID
                                       AND ISNULL(ss.SoldDate2 , '12/31/2999') = ISNULL(cc.SoldDate2 ,
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
	--select b.* from #bucket b
	--Inner JOIN (select bc.RateDetID, Max(bc.PremID) as PremID
	--  from #bucket bc where bc.[Premise Status] = 'Inactive'  
	--  group by bc.RateDetID having COUNT(*) > 1 ) b1 
	--	on b1.RateDetID = b.RateDetID and b1.PremID = b.PremID
	--where b.[Premise Status] = 'Inactive'	
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


