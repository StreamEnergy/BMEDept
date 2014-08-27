USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Contract_EDF_NG]    Script Date: 08/26/2014 13:31:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Preetha Sridhar						Source view for generating the NATURAL GAS flat file that is sent
						Eric McCormick						via FTP to EDF.
															08.12:  Still in DEVELOPMENT; waiting on customer acceptance.
															08.13:  Comment out "AND rc.RateClass is not null" per Alex Soich.  ERM
						
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/


CREATE VIEW [dbo].[v_Contract_EDF_NG]
AS
    SELECT DISTINCT
            L.LDCID ,
            L.LDCShortName AS LDCCode ,
            L.LDCShortName AS WeatherZone ,
            L.LDCShortName AS LoadZone ,
            A.State AS StateAbbr ,
            C.CustID ,
            C.CustNo ,
            P.PremID ,
            P.PremNo ,
            RD.RateDetID ,
            MR.MeterNo , 
	--MR.MeterID,
            RC.RateClass ,
            ELP.LoadProfile AS LoadProfile ,
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
            CASE WHEN D.PlanType = '1' THEN RD.RateAmt				-- If TERM THEN use RateAmt
                 WHEN D.PlanType = '2'
                      AND RD.RateAmt <> 0 THEN RD.RateAmt				-- If VARIABLE AND RateAmt NOT zero THEN use RateAmt
                 WHEN D.PlanType = '2'
                      AND RIR.IndexRate <> 0 THEN RIR.IndexRate			-- If VARIABLE AND RateAmt IS zero AND IndexRate IS NOT NULL THEN use IndexRate
										-- If VARIABLE AND RateAmt IS zero AND IndexRate IS NULL THEN use the IndexRate for the "brown" version of the "green" product.
            END AS Price ,
            D.ProductCode ,
            D.ProductName ,
	--P.PremType,							-- premtype added by ERM 11.30.12	
            A.Zip ,
            CASE WHEN d.PlanType = '2' THEN 'Monthly'
                 ELSE CONVERT(VARCHAR(10) , expirationdate , 101)
            END AS Date ,
            CASE WHEN c.CompanyName IS NULL
                      AND c.custtype = 'C'
                 THEN REPLACE(c.CustName , '.,' , '')
                 ELSE REPLACE(c.CompanyName , ',' , '')
            END AS CompanyName
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
    WHERE   ( ( ( ( GETDATE() BETWEEN RD.EffectiveDate
                              AND     ISNULL(RD.ExpirationDate , '1/1/2099')
                    AND RD.Active = 1
                  )	-- active current contract
                  OR ( GETDATE() <= RD.EffectiveDate
                       AND RD.Active = 1
                     )	-- pending future contract												
                )
                AND ( ( P.StatusID IN ( '1' , '5' , '7' , '8' , '9' , '10' )) )															-- on-flow statuses
                AND P.premtype = 'gas'
              )
              AND GETDATE() < ISNULL(MR.Dateto , '1/1/2099')
              AND ( ( rd.EffectiveDate <= rd.ExpirationDate
                      AND d.PlanType = '1'
                    )
                    OR ( rd.ExpirationDate IS NULL )
                  )
            )
            AND d.PlanType IS NOT NULL
--	AND rc.RateClass is not null














GO


