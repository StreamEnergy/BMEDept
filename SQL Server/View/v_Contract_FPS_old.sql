USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Contract_FPS_old]    Script Date: 08/26/2014 09:34:51 ******/
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

ALTER VIEW [dbo].[v_Contract_FPS_old]
AS
    SELECT DISTINCT
            C.LDCID ,
            L.LDCShortName AS LDCCode ,
            L.LDCShortName AS WeatherZone ,
            L.LDCShortName AS LoadZone ,
            M.StateAbbr ,
            C.CustID ,
            C.CustNo ,
            C.PremID ,
            C.PremNo ,
            C.RateDetID ,
            MR.MeterNo ,
            RC.RateClass ,
            LP.LoadProfile ,
            S.Strata ,
            C.BeginServiceDate ,
            C.ENDServiceDate ,
            C.EffectiveDate ,
            C.ExpirationDate ,
            C.PlanType ,
            C.Active ,
            C.ContractStatus ,
            C.StatusID AS PremiseStatusID ,
            C.PremiseStatus ,
            CT.CustType ,
            C.serviceCycle
    FROM    ( SELECT    VC.* ,
                        CASE WHEN GETDATE() BETWEEN VC.EffectiveDate
                                            AND     ISNULL(VC.ExpirationDate ,
                                                           '1/1/2099')
                                  AND VC.Active = 1 THEN 'Active'
                             WHEN GETDATE() < VC.EffectiveDate
                                  AND VC.Active = 1 THEN 'PENDing'
                             ELSE 'TBD'
                        END AS ContractStatus
              FROM      v_Contract VC
              WHERE     ( ( GETDATE() BETWEEN VC.EffectiveDate
                                      AND     ISNULL(VC.ExpirationDate ,
                                                     '1/1/2099')
                            AND VC.Active = 1
                          )	-- active current contract
                          OR ( GETDATE() < VC.EffectiveDate
                               AND VC.Active = 1
                             )													-- pending future contract
                        )
                        AND ( VC.StatusID IN ( '1' , '5' , '7' , '8' , '9' ,
                                               '10' )															-- on-flow statuses
                              OR ( VC.StatusID = '6'
                                   AND VC.EndServiceDate > GETDATE()
                                 )
                            ) 												-- Added 10.12.12 per B. Berend												
                        AND vc.premtype = 'elec'
            ) C
    LEFT JOIN Stream.dbo.Meter MR ON c.PremID = mr.PremID
    LEFT JOIN Stream.dbo.EdiRateClass RC ON mr.EdiRateClassId = rc.EdiRateClassId
    LEFT JOIN Stream.dbo.EdiLoadProfile LP ON mr.EdiLoadProfileId = lp.EdiLoadProfileId
    LEFT JOIN StreamInternal.dbo.RateClassStrataLkp S ON rc.rateclass = s.IstaRateClass
                                                         AND lp.loadprofile = s.IstaLoadProfile
                                                         AND c.ldcid = s.LDCID
    LEFT JOIN stream.dbo.LDCLookup L ON l.LDCID = c.LDCID
    LEFT JOIN streaminternal.dbo.Market M ON l.MarketID = m.MarketId
    LEFT JOIN Stream.dbo.Customer CC ON cc.CustID = c.CustID
    LEFT JOIN Stream.dbo.CustomerType CT ON ct.CustomerTypeID = cc.CustomerTypeID
    WHERE   GETDATE() < ISNULL(mr.Dateto , '1/1/2099') --if meter record exists, we only want active meter












GO


