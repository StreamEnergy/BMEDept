USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_TX_MoveInMoveDetails]    Script Date: 08/18/2014 15:12:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





--============================================================================
--************************** Notes/Change Log *******************************
--==========================================================================
--Date				Author						Description
--08/08/2014 			Jide Akintoye			Count # of Move in Move out Gains and Loss by combining
--												the Net Additions, the total Transfer of Service (TOS)(same customer, diff esiid, within 30 days)
--												,count of the R1 (Diff Customer, Same ESIID) and 
--												the count of the R2 (same esiid, enroll within 90days after drop)
														   



--==========================================================================						   
--*/

CREATE PROCEDURE [dbo].[sp_TX_MoveInMoveDetails]
    ( @StartDate DATETIME
    , @EndDate DATETIME
--, @State NVARCHAR (MAX) 
--, @Status NVARCHAR (MAX) 

    )
AS
    BEGIN


-- --Begin Test Section
    --DECLARE @StartDate DATETIME = '10/31/2013'
    --DECLARE @EndDate DATETIME = '03/31/2014'
--DECLARE @SDate VARCHAR(7)
----DECLARE @EDate VARCHAR(7)
------End Test Section
SELECT DISTINCT --TOP 20000
        'AcctNumber' = CP.CustNo
      , CP.FirstName
      , CP.LastName
      , EmailAddress = CP.Email
      , 'MVO_Address' = ED1.Address + ' ' + ED1.[ADDRESS_2]
      , 'MVI_Address' = ED.Address + ' ' + ED.[ADDRESS_2]
      , 'MVO_Date' = CAST(CP1.EndServiceDate AS DATE)
      , 'MVI_Date' = CAST(CP.BeginServiceDate AS DATE)
      , 'MVO_ESIID' = TOS.EndPremNo
      , 'MVI_ESIID' = TOS.PremNo
FROM    [StreamInternal].dbo.TX_Enroll_TOS TOS
LEFT JOIN [StreamInternal].dbo.Ref_ESIID ED ON TOS.PremNo = ED.ESIID
LEFT JOIN [StreamInternal].dbo.Ref_ESIID ED1 ON TOS.EndPremNo = ED1.ESIID
INNER JOIN [StreamInternal].dbo.CustomerProfile CP ON CP.PremNo = TOS.PremNo
                                                      AND CP.CustNo = TOS.CustNo
                                                      AND CP.BeginServiceDate = TOS.BeginServiceDate
INNER JOIN [StreamInternal].dbo.CustomerProfile CP1 ON CP1.PremNo = TOS.EndPremNo
                                                       AND CP1.CustNo = TOS.EndCustNo
                                                       AND CP1.EndServiceDate = TOS.EndServiceDate
WHERE   CP.BeginServiceDate >= @StartDate
        AND CP.BeginServiceDate <= @EndDate
--ORDER BY MVI_Date
ORDER BY MVI_Date
    END








GO


