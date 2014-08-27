USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Contract_old]    Script Date: 08/26/2014 13:34:31 ******/
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

CREATE VIEW [dbo].[v_Contract_old]
AS
    SELECT DISTINCT
            c.CustID ,
            c.CustNo ,
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
            d.ProductCode ,
            d.ProductName ,
            rit.RateIndexType ,
            d.PlanType ,
            p.LastModifiedDate AS LastUpdateDate ,
            p.StatusID ,
            p.ServiceCycle ,
 -- PremType Added by ERM 11.30.12
            p.PremType ,
 -- LBMPName Added by ERM 12.05.12
            lbmp.LBMPName ,
 -- MeterNo Added by ERM 12.18.12
            MR.MeterNo ,
 -- RateClass Added by ERM 12.18.12
            RC.RateClass ,
 -- LoadProfile Added by ERM 12.18.12
            LP.LoadProfile ,
 -- Strata Added by ERM 12.18.12
            S.Strata ,
            p.AddrID
    FROM    STREAM.dbo.Customer C
    LEFT JOIN STREAM.dbo.Premise P ON P.CustID = C.CustID
    JOIN    STREAM.dbo.RateDetail RD ON RD.RateID = C.RateID
                                        AND RD.Active = 1
    LEFT JOIN STREAM.dbo.RateIndexType RIT ON RIT.RateIndexTypeID = RD.FixedCapRate
    LEFT JOIN STREAM.dbo.RateTransition RT ON RD.RateTransitionId = RT.RateTransitionID
    LEFT JOIN STREAM.dbo.Product D ON D.RateID = RT.RateID
    LEFT JOIN STREAM.dbo.RateIndexRange RIR ON RIR.RateIndexTypeID = RD.FixedCapRate
                                               AND GETDATE() BETWEEN RIR.DateFrom AND RIR.DateTo -- there are multiple prices, you need to specify for which date
    LEFT JOIN STREAM.dbo.LDCLookup L ON L.LDCID = P.LDCID
    LEFT JOIN STREAM.dbo.PremiseStatus PS ON P.StatusID = PS.PremiseStatusID
    LEFT JOIN STREAM.dbo.terms T ON T.termsid = D.termsid

-- STREAM.dbo.LBMP Added by ERM 12.05.12
    LEFT JOIN STREAM.dbo.LBMP LBMP ON P.LBMPId = LBMP.LBMPId

-- Stream.dbo.Meter Added by ERM 12.18.12
    LEFT JOIN Stream.dbo.Meter MR ON P.PremID = MR.PremID

-- Stream.dbo.EdiRateClass Added by ERM 12.18.12
    LEFT JOIN Stream.dbo.EdiRateClass RC ON MR.EdiRateClASsId = RC.EdiRateClASsId

-- Stream.dbo.EdiLoadProfile Added by ERM 12.18.12
    LEFT JOIN Stream.dbo.EdiLoadProfile LP ON MR.EdiLoadProfileId = LP.EdiLoadProfileId

-- StreamInternal.dbo.RateClassStrataLkp Added by ERM 12.18.12
    LEFT JOIN StreamInternal.dbo.RateClassStrataLkp S ON RC.rateclass = S.IstaRateClass
                                                         AND LP.loadprofile = S.IstaLoadProfile
                                                         AND L.ldcid = S.LDCID







GO


