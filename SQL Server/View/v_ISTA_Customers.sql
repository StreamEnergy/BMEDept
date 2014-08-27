USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_ISTA_Customers]    Script Date: 08/26/2014 15:08:10 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Preetha Sridhar						Customer extract from ISTA for use by the FPS system and ISTA
						& Eric McCormick					various customer related reports used by the wholesale group.  
															07.13:  Used as FPS production source. 
															
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[v_ISTA_Customers]
AS
    SELECT DISTINCT
            L.LDCID ,
            L.LDCShortName AS LDCCode ,
            CASE WHEN L.LDCID IN ( 1 , 2 , 3 , 4 , 5 )
                 THEN cLP.WeatherZoneCode
                 ELSE L.LDCShortName
            END AS WeatherZoneCode ,
            CASE WHEN L.LDCID IN ( 1 , 2 , 3 , 4 , 5 )
                 THEN SUBSTRING(TS.LoadZone , 1 , LEN(TS.LoadZone) - 4)
                 ELSE L.LDCShortName
            END AS LoadZoneCode ,
            A.STATE ,
            C.CustID ,
            C.CustNo ,
            P.PremID ,
            P.PremNo ,
            RD.RateDetID ,
            MR.MeterNo ,
            MR.MeterID ,
            RC.RateClass ,
            CASE WHEN L.LDCID IN ( 1 , 2 , 3 , 4 , 5 ) THEN CLP.LoadProfile			-- for TX
                 ELSE ELP.LoadProfile			-- for NE
            END AS LoadProfile ,
            NS.Strata ,
            P.BeginServiceDate ,
            P.EndServiceDate ,
            RD.EffectiveDate ,
            RD.ExpirationDate ,
            CASE WHEN D.PlanType = '1' THEN 'FIXED'
                 WHEN D.PlanType = '2' THEN 'VARIABLE'
            END AS PlanType ,
            RD.ACTIVE ,
            CASE WHEN GETDATE() BETWEEN RD.EffectiveDate
                                AND     ISNULL(rd.ExpirationDate , '1/1/2099')
                      AND rd.Active = 1 THEN 'Active'
                 WHEN GETDATE() < rd.EffectiveDate
                      AND rd.Active = 1 THEN 'Pending'
                 ELSE 'TBD'
            END AS ContractStatus ,
            P.StatusID AS PremiseStatusID ,
            PS.STATUS AS PremiseStatus ,
            CASE WHEN C.CustType = 'R' THEN 'RESIDENTIAL'
                 WHEN C.CustType = 'C' THEN 'COMMERCIAL'
            END AS CustType ,
            P.ServiceCycle ,
            P.CreateDate ,						-- Premise record added new
            RD.RateID ,
            RD.RateAmt ,							-- TERM/FIXED Rate	(Redundant?)
            RIR.IndexRate ,						-- MTM Rate			(Redundant?)
            D.ProductCode ,
            D.ProductName ,
            RIT.RateIndexType ,
            P.LastModifiedDate AS LastUpdateDate ,
            P.PremType ,							-- premtype added by ERM 11.30.12	
            LBMP.LBMPName ,						-- LBMPName Added by ERM 12.05.12
            C.CustName ,
            C.ContractID ,						-- ERM the ContractID on the Customer table is always NULL. (but Preetha wanted it left in!)
            CASE WHEN D.PlanType = '1' THEN RD.RateAmt				-- If TERM THEN use RateAmt
                 WHEN D.PlanType = '2'
                      AND RD.RateAmt <> 0 THEN RD.RateAmt				-- If VARIABLE AND RateAmt NOT zero THEN use RateAmt
                 WHEN D.PlanType = '2'
                      AND RIR.IndexRate <> 0 THEN RIR.IndexRate			-- If VARIABLE AND RateAmt IS zero AND IndexRate IS NOT NULL THEN use IndexRate
										-- If VARIABLE AND RateAmt IS zero AND IndexRate IS NULL THEN use the IndexRate for the "brown" version of the "green" product.
            END AS Price ,
            CLP.ProfileGroupCode AS ERCOTProfile ,
            TS.StationCode ,
            D.ProductID ,
            L.DUNS ,
            A.Zip
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
    LEFT JOIN Stream.dbo.LoadProfile CLP -- TX
            ON MR.EdiLoadProfileID = CLP.LoadProfileID
    LEFT JOIN StreamInternal.dbo.RateClassStrataLkp NS -- NE
            ON RC.RateClass = NS.ISTARateClass
               AND ELP.LoadProfile = NS.ISTALoadProfile
               AND L.LDCID = NS.LDCID
    LEFT JOIN StreamInternal.dbo.RateClassStrataLkp ES -- TX 
            ON RC.RateClass = ES.ISTARateClass
               AND CLP.loadprofile = ES.ISTALoadProfile
               AND L.LDCID = ES.LDCID
    LEFT JOIN StreamInternal.dbo.Market M ON L.MarketID = M.MarketID
    LEFT JOIN Stream.dbo.Address A ON A.AddrID = P.AddrID
    LEFT JOIN Stream.dbo.CustomerType CT ON CT.CustomerTypeID = C.CustomerTypeID
    LEFT JOIN Stream.dbo.TransmissionStation TS ON CLP.TransmissionStation = TS.StationCode
    WHERE   ( ( ( GETDATE() BETWEEN RD.EffectiveDate
                            AND     ISNULL(RD.ExpirationDate , '1/1/2099')
                  AND RD.Active = 1
                )	-- active current contract
                OR ( GETDATE() <= RD.EffectiveDate
                     AND RD.Active = 1
                   )													-- pending future contract
              )
              AND ( ( P.StatusID IN ( '1' , '5' , '7' , '8' , '9' , '10' )
                      AND ( P.EndServiceDate >= GETDATE()
                            OR P.endservicedate IS NULL
                          )
                    )															-- on-flow statuses
                    OR ( P.StatusID = '6'
                         AND P.EndServiceDate >= GETDATE()
                       )
                  ) 					-- Added 10.12.12 per B. Berend												
              AND P.premtype = 'elec'
            )
            AND GETDATE() < ISNULL(MR.Dateto , '1/1/2099')







GO


