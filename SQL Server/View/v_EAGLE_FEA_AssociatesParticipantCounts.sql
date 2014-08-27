USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_AssociatesParticipantCounts]    Script Date: 08/26/2014 13:41:37 ******/
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

CREATE VIEW [dbo].[v_EAGLE_FEA_AssociatesParticipantCounts]
AS
    -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--Associates Participant Counts
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SELECT  ah.[IA Number] ,
        ah.Name_First + ' ' + ah.Name_Last [IA Name] ,
        cc.[Customer Number] [Designated Account] ,
        cc.Name_First + ' ' + cc.Name_Last [Designated Name] ,
        cc.DStatusDesc ,
        bc.ProgramCode ,
        bc.NumberReferrals
FROM    ( SELECT    AccountNumber ,
                    DesignatedAccountNumber ,
                    ProgramCode ,
                    MAX(NumberCust) NumberReferrals
          FROM      v_EAGLE_FEA_AssociatesByProgramCode WITH ( NOLOCK )
          GROUP BY  AccountNumber ,
                    DesignatedAccountNumber ,
                    ProgramCode
        ) bc
INNER JOIN EAGLE.dbo.tblAssociatesAndHomesites ah WITH ( NOLOCK ) ON ah.[IA Number] = bc.AccountNumber
INNER JOIN EAGLE.dbo.tblCustomers cc WITH ( NOLOCK ) ON cc.[Customer Number] = bc.DesignatedAccountNumber


GO


