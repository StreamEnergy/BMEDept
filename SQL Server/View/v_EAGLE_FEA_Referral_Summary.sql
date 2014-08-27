USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_Referral_Summary]    Script Date: 08/26/2014 13:49:10 ******/
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

CREATE VIEW [dbo].[v_EAGLE_FEA_Referral_Summary]
AS
    SELECT  CASE WHEN LEFT(ra.designatedAccountNumber , 1) = 'C'
                 THEN 'ELECTRICITY'
                 ELSE 'GAS'
            END ComodityType ,
            rp.AccountNumber ParticipantAccountNumber ,
            cp.Name_First + ' ' + cp.Name_Last ParticipantName ,
            ra.DesignatedAccountNumber DesignatedAccountNumber ,
            COUNT(*) ReferralCount
    FROM    EAGLE.dbo.RPDesignatedAccount ra WITH ( NOLOCK )
    INNER JOIN EAGLE.dbo.RPParticipant rp WITH ( NOLOCK ) ON rp.AccountNumber = ra.ParticipantAccountNumber
    INNER JOIN EAGLE.dbo.RPReferredAccount rr WITH ( NOLOCK ) ON rr.DesignatedAccountNumber = ra.DesignatedAccountNumber
    INNER JOIN EAGLE.dbo.tblCustomers cc WITH ( NOLOCK ) ON cc.[Customer Number] = rr.ReferredAccountNumber
    INNER JOIN [Eagle].[dbo].[tblAssociatesAndHomesites] cp ON cp.[IA Number] = rp.AccountNumber
    WHERE   rp.AccountStatus = 'Active'
            AND ra.AccountStatus = 'Active'
            AND rr.AccountStatus = 'Active'
-- AND	rp.AccountNumber = 'A2717382'
    GROUP BY ra.ProgramCode ,
            CASE WHEN LEFT(ra.designatedAccountNumber , 1) = 'C'
                 THEN 'ELECTRICITY'
                 ELSE 'GAS'
            END ,
            rp.AccountNumber ,
            cp.Name_First + ' ' + cp.Name_Last ,
            ra.DesignatedAccountNumber			







GO


