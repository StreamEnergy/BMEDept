USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Contract_EDF_Modified]    Script Date: 08/26/2014 13:31:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO














CREATE VIEW [dbo].[v_Contract_EDF_Modified]
AS
SELECT      DISTINCT 
            c.LDCID, 
            l.LDCShortName                            AS LDCCode,
            l.LDCShortName                            AS WeatherZone,
            l.LDCShortName                            AS LoadZone,
            m.StateAbbr,
            c.CustID,
            c.CustNo,  
            c.PremID,
            c.PremNo,
            c.RateDetID,
            mr.MeterNo,
            rc.RateClASs,
            lp.LoadProfile,
            s.Strata, 
            c.BeginServiceDate, 
            c.ENDServiceDate, 
            c.EffectiveDate, 
            c.ExpirationDate,
      CASE  
            WHEN c.PlanType = '1' 
                  THEN 'FIXED'
            WHEN c.PlanType = '2' 
                  THEN 'VARIABLE'
      END                                                   AS PlanType, 

      c.ACTIVE, 
      c.ContractStatus, 
      c.StatusID                                      AS PremiseStatusID,     
      c.PremiseStatus,
      
      CASE
            WHEN cc.CustType = 'R' 
                  THEN 'RESIDENTIAL'
            WHEN cc.CustType = 'C' 
                  THEN 'COMMERCIAL'
      END                                                   AS CustType,
      
      c.serviceCycle,
      
      CASE 
            WHEN c.PlanType = '1' 
                  THEN c.RateAmt                      -- If TERM THEN use RateAmt
            WHEN c.PlanType = '2' 
            AND c.RateAmt <> 0 
                  THEN c.RateAmt                      -- If VARIABLE AND RateAmt NOT zero THEN use RateAmt
            WHEN c.PlanType = '2' 
            AND c.IndexRate <> 0 
                  THEN c.IndexRate              -- If VARIABLE AND RateAmt IS zero AND IndexRate IS NOT NULL THEN use IndexRate
            ELSE( SELECT      DISTINCT vc.IndexRate 
                        FROM  v_Contract vc 
                        WHERE vc.ProductCode = REPLACE(c.RateIndexType, '012GRN_','')
                  )                                         -- If VARIABLE AND RateAmt IS zero AND IndexRate IS NULL THEN use the IndexRate for the "brown" version of the "green" product.
      END                                                   AS Price,
      
      c.ProductCode,    
      c.ProductName,
      a.ZIP,
      
      CASE 
            WHEN c.PlanType = '2' 
                  THEN 'Monthly' 
            ELSE CONVERT(varchar(10), expirationdate, 101) 
      END                                                   AS Date,
      
      CASE 
            WHEN cc.CompanyName IS NULL 
            AND cc.custtype = 'C' 
                  THEN REPLACE(cc.CustName,'.,','') 
            ELSE REPLACE(cc.CompanyName,',','') 
      END                                                   AS CompanyName 
      
FROM
(
      SELECT C2.*,
      CASE 
            WHEN  CONVERT(DATE, GETDATE(), 110) BETWEEN (CONVERT(DATE, C2.EffectiveDate, 110)) 
            AND CONVERT(DATE, ISNULL(C2.ExpirationDate, '1/1/2099'), 110) 
            AND C2.Active = 1
                  THEN 'Active'
            WHEN CONVERT(DATE, GETDATE(), 110) < CONVERT(DATE, C2.EffectiveDate, 110) 
            AND C2.Active = 1
                  THEN 'PENDing'
            ELSE 'TBD'
      END                                                   AS ContractStatus 
      
      FROM v_Contract C2
      WHERE  
      (
            ( CONVERT(DATE, GETDATE(), 110) BETWEEN 
            CONVERT(DATE, C2.EffectiveDate, 110) AND CONVERT(DATE, ISNULL(C2.ExpirationDate, '1/1/2099'), 110)
                  AND C2.Active = 1)                  --active current contract
            OR
            (CONVERT(DATE, GETDATE(), 110) < CONVERT(DATE, C2.EffectiveDate, 110) 
                  AND C2.Active = 1)                  --pending future contract
      )     

      AND C2.StatusID IN ('1','5','7','8','9','10')   -- on-flow statuses
      AND         C2.premtype = 'elec' 
) C

LEFT JOIN Stream.dbo.Meter mr 
ON    c.PremID                      = mr.PremID

LEFT JOIN Stream.dbo.EdiRateClASs rc 
ON    mr.EdiRateClASsId       = rc.EdiRateClASsId

LEFT JOIN Stream.dbo.EdiLoadProfile lp 
ON    mr.EdiLoadProfileId           = lp.EdiLoadProfileId

LEFT JOIN StreamInternal.dbo.RateClASsStrataLkp s 
ON    rc.rateclASs                  = s.IstaRateClASs 
AND lp.loadprofile                  = s.IstaLoadProfile 
AND c.ldcid                         = s.LDCID

LEFT JOIN stream.dbo.LDCLookup l 
ON l.LDCID                          = c.LDCID

LEFT JOIN streaminternal.dbo.Market m 
ON l.MarketID                       = m.MarketId

LEFT JOIN Stream.dbo.Customer cc 
ON cc.CustID                        = c.CustID

LEFT JOIN stream.dbo.Address a 
ON a.AddrID                         = cc.MailAddrId

LEFT JOIN Stream.dbo.CustomerType ct 
ON ct.CustomerTypeID          = cc.CustomerTypeID       

WHERE  CONVERT(DATE, GETDATE(), 110) < ISNULL(mr.Dateto,'1/1/2099') --if meter record exists, we only want active meter 
  -- convert function is used to retrieve the date part only eliminating time, so the date comparison for contract dates will be accurate  
 AND        c.PlanType              IS NOT NULL
AND         ((CONVERT(DATE, c.EffectiveDate, 110) <= CONVERT(DATE, c.ExpirationDate, 110)) --AND c.PlanType = '1') 
            OR 
             (c.ExpirationDate      IS NULL))
AND         rc.RateClASs            IS NOT NULL
-- and s.Strata is not null
AND         (LEN(lp.LoadProfile) != 0)
--and  c.custno = '3000144835'









GO


