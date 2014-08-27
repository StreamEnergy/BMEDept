USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_CustomersParticipantCounts]    Script Date: 08/26/2014 13:44:01 ******/
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

CREATE VIEW [dbo].[v_EAGLE_FEA_CustomersParticipantCounts]
AS
    -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--Customer Participant Counts
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SELECT  ah.[Customer Number] [Participant Number] ,
        ah.Name_First + ' ' + ah.Name_Last [Participant Name] ,
        cc.[Customer Number] [Designated Account] ,
        cc.Name_First + ' ' + cc.Name_Last [Designated Name] ,
        cc.DStatusDesc ,
        bc.ProgramCode ,
        bc.NumberReferrals
FROM    ( SELECT    AccountNumber ,
                    DesignatedAccountNumber ,
                    ProgramCode ,
                    MAX(NumberCust) NumberReferrals
          FROM      v_EAGLE_FEA_CustomersByProgramCode WITH ( NOLOCK )
          GROUP BY  AccountNumber ,
                    DesignatedAccountNumber ,
                    ProgramCode
        ) bc
INNER JOIN EAGLE.dbo.tblCustomers ah WITH ( NOLOCK ) ON ah.[Customer Number] = bc.AccountNumber
INNER JOIN EAGLE.dbo.tblCustomers cc WITH ( NOLOCK ) ON cc.[Customer Number] = bc.DesignatedAccountNumber

GO


