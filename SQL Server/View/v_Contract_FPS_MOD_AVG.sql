USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Contract_FPS_MOD_AVG]    Script Date: 08/26/2014 13:33:26 ******/
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

CREATE VIEW [dbo].[v_Contract_FPS_MOD_AVG]
AS
    SELECT  L.LDCID ,
            L.LDCShortName AS LDCCode ,
            COALESCE(LBMP.EDICode , L.LDCShortName) AS WeatherZone ,--added by Lor to get NY loadzone
            COALESCE(LBMP.EDICode , L.LDCShortName) AS LoadZone ,
            A.STATE AS StateAbbr ,
            C.CustID ,
            C.CustNo ,
            P.PremID ,
            P.PremNo ,
            MIN(RD.RateDetID) AS RateDetID ,
            MR.MeterNo ,
            MR.MeterID ,
            RC.RateClass ,
            ELP.LoadProfile AS LoadProfile ,
            NS.Strata ,
            P.BeginServiceDate ,
            P.EndServiceDate ,
            RD.EffectiveDate ,
            RD.ExpirationDate ,
            D.PlanType ,
            RD.Active ,
            CASE WHEN CONVERT(DATE , GETDATE() , 110) BETWEEN CONVERT(DATE , RD.EffectiveDate , 110)
                                                      AND     ISNULL(CONVERT(DATE , rd.ExpirationDate , 110) ,
                                                              '1/1/2099')
                      AND rd.Active = 1 THEN 'Active'
                 WHEN CONVERT(DATE , GETDATE() , 110) < CONVERT(DATE , rd.EffectiveDate , 110)
                      AND rd.Active = 1 THEN 'Pending'
                 ELSE 'TBD'
            END AS ContractStatus ,
            P.StatusID AS PremiseStatusID ,
            PS.STATUS AS PremiseStatus ,
            c.CustType ,
            P.ServiceCycle ,
            AVG(CASE WHEN D.PlanType = '1' THEN RD.RateAmt -- If TERM THEN use RateAmt
                    --WHEN D.PlanType = '2' 
                    --AND RD.RateAmt <> 0 
                    --    THEN RIR.IndexRate                        
                     WHEN D.PlanType = '2'
                --AND RIR.IndexRate <> 0            -- if variable use rir.indexrate from Stream.dbo.RateIndexRange     per Mark c
                          THEN RIR.IndexRate
                END) AS Rate
--D.ProductCode,  
--D.ProductName
    FROM    Stream.dbo.Customer C
    LEFT JOIN Stream.dbo.Premise P ON P.CustID = C.CustID
    JOIN    Stream.dbo.RateDetail RD ON RD.RateID = C.RateID
    LEFT JOIN Stream.dbo.RateIndexType RIT ON RIT.RateIndexTypeID = RD.FixedCapRate
    LEFT JOIN Stream.dbo.RateTransition RT ON RD.RateTransitionId = RT.RateTransitionID
    LEFT JOIN Stream.dbo.Product D ON D.RateID = RT.RateID
    LEFT JOIN Stream.dbo.RateIndexRange RIR ON RIR.RateIndexTypeID = RD.FixedCapRate
                                               AND GETDATE() BETWEEN RIR.DateFrom AND RIR.DateTo
    LEFT JOIN Stream.dbo.LDCLookup L ON L.LDCID = P.LDCID
    LEFT JOIN Stream.dbo.PremiseStatus PS ON P.StatusID = PS.PremiseStatusID
    LEFT JOIN Stream.dbo.terms T ON T.TermsID = D.TermsID
    LEFT JOIN Stream.dbo.LBMP LBMP ON P.LBMPID = LBMP.LBMPID
    LEFT JOIN Stream.dbo.Meter MR ON P.PremID = MR.PremID
    LEFT JOIN Stream.dbo.EdiRateClass RC ON MR.EdiRateClassID = RC.EdiRateClassID
    LEFT JOIN Stream.dbo.EdiLoadProfile ELP -- NE
            ON MR.EdiLoadProfileID = ELP.EdiLoadProfileID 

--LEFT JOIN Stream.dbo.LoadProfile                          CLP   -- TX
 --ON MR.EdiLoadProfileID  = CLP.LoadProfileID
    LEFT JOIN StreamInternal.dbo.RateClassStrataLkp NS -- NE
            ON RC.RateClass = NS.ISTARateClass
               AND ELP.LoadProfile = NS.ISTALoadProfile
               AND L.LDCID = NS.LDCID 
    
 --LEFT JOIN StreamInternal.dbo.RateClassStrataLkp     ES    -- TX 
  --ON              RC.RateClass                  = ES.ISTARateClass 
  --AND             CLP.loadprofile               = ES.ISTALoadProfile  
  --AND             L.LDCID                             = ES.LDCID
    LEFT JOIN StreamInternal.dbo.Market M ON L.MarketID = M.MarketID
    LEFT JOIN Stream.dbo.Address A ON A.AddrID = P.AddrID
    LEFT JOIN Stream.dbo.CustomerType CT ON CT.CustomerTypeID = C.CustomerTypeID

--LEFT JOIN Stream.dbo.TransmissionStation                  TS
--ON     CLP.TransmissionStation = TS.StationCode
    WHERE   ( CONVERT(DATE , GETDATE() , 110) BETWEEN CONVERT(DATE , RD.EffectiveDate , 110)
                                              AND     ISNULL(CONVERT(DATE , RD.ExpirationDate , 110) ,
                                                             '1/1/2099')
              AND RD.Active = 1 -- active current contract
              OR CONVERT(DATE , GETDATE() , 110) <= CONVERT(DATE , RD.EffectiveDate , 110)
              AND RD.Active = 1 -- pending future contract
            )
            AND ( P.StatusID IN ( '1' , '5' , '7' , '8' , '9' , '10' )
                  AND ( CONVERT(DATE , P.EndServiceDate , 110) >= CONVERT(DATE , GETDATE() , 110)
                        OR CONVERT(DATE , P.endservicedate , 110) IS NULL
                      ) -- on-flow statuses
                  OR P.StatusID = '6'
                  AND CONVERT(DATE , P.EndServiceDate , 110) >= CONVERT(DATE , GETDATE() , 110)
                ) -- Added 10.12.12 per B. Berend                                                                       
            AND P.premtype = 'elec'
            AND CONVERT(DATE , GETDATE() , 110) < ISNULL(CONVERT(DATE , MR.Dateto , 110) ,
                                                         '1/1/2099')
    -- AND (RD.ExpirationDate  > P.BeginServiceDate       OR RD.ExpirationDate IS NULL)
            AND ( P.BeginServiceDate <> P.EndServiceDate
                  OR P.EndServiceDate IS NULL
                )
--and L.LDCShortName  = 'PECO'
--and c.CustType = 'R'
--where CustNo ='3000125499'
--0where plantype is null
--or rate is null
GROUP BY    L.LDCID ,
            L.LDCShortName ,
            COALESCE(LBMP.EDICode , L.LDCShortName) ,
            A.STATE ,
            C.CustID ,
            C.CustNo ,
            P.PremID ,
            P.PremNo ,
            MR.MeterNo ,
            MR.MeterID ,
            RC.RateClass ,
            ELP.LoadProfile ,
            NS.Strata ,
            P.BeginServiceDate ,
            P.EndServiceDate ,
            RD.EffectiveDate ,
            RD.ExpirationDate ,
            D.PlanType ,
            RD.Active ,
            CASE WHEN CONVERT(DATE , GETDATE() , 110) BETWEEN CONVERT(DATE , RD.EffectiveDate , 110)
                                                      AND     ISNULL(CONVERT(DATE , rd.ExpirationDate , 110) ,
                                                              '1/1/2099')
                      AND rd.Active = 1 THEN 'Active'
                 WHEN CONVERT(DATE , GETDATE() , 110) < CONVERT(DATE , rd.EffectiveDate , 110)
                      AND rd.Active = 1 THEN 'Pending'
                 ELSE 'TBD'
            END ,
            P.StatusID ,
            PS.STATUS ,
            c.CustType ,
            P.ServiceCycle;





GO


