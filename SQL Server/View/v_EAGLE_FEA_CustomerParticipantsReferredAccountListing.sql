USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_CustomerParticipantsReferredAccountListing]    Script Date: 08/26/2014 13:43:16 ******/
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

CREATE VIEW [dbo].[v_EAGLE_FEA_CustomerParticipantsReferredAccountListing]
AS
    -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
--Customer Participants Referral listing
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
SELECT	DISTINCT
        ra.ProgramCode ProgramName ,
        CASE WHEN LEFT(ra.designatedAccountNumber , 1) = 'C'
             THEN 'ELECTRICITY'
             ELSE 'GAS'
        END ComodityType ,
        rp.AccountNumber ParticipantAccountNumber ,
        cc.Name_First + ' ' + cc.Name_Last ParticipantName ,
        ra.DesignatedAccountNumber DesignatedAccountNumber ,
        rr.ReferredAccountNumber ReferredAccountNumber ,
        cc.Name_First + ' ' + cc.Name_Last ReferredName ,
        CC.[app date] AppDate ,
        ROW_NUMBER() OVER ( PARTITION BY rp.AccountNumber ,
                            ra.DesignatedAccountNumber ORDER BY cc.[App Date] ) ReferredCount ,
        rr.AccountStatus ReferredAccountStatus ,
        cc.[Email] ParticipantEMail ,
        Cc.[Phone] ParticipantPhone ,
        cc.[City] ParticipantCity ,
        cc.[State] ParticipantState ,
        cc.[Zip] ParticipantZip
FROM    EAGLE.dbo.RPDesignatedAccount ra WITH ( NOLOCK )
INNER JOIN EAGLE.dbo.RPParticipant rp WITH ( NOLOCK ) ON rp.AccountNumber = ra.ParticipantAccountNumber
INNER JOIN EAGLE.dbo.RPReferredAccount rr WITH ( NOLOCK ) ON rr.DesignatedAccountNumber = ra.DesignatedAccountNumber
INNER JOIN EAGLE.dbo.tblCustomers cc WITH ( NOLOCK ) ON cc.[Customer Number] = rp.AccountNumber

--INNER JOIN 
--	EAGLE.dbo.tblCustomers				cp WITH (NOLOCK) 
--ON		cc.[Customer Number]		= rr.ReferredAccountNumber	
WHERE   rp.AccountStatus = 'Active'
        AND LEFT(rp.AccountNumber , 1) <> 'A'
        AND rr.AccountStatus IN ( 'Active' , 'Pending' , 'PreVerify' )





GO


