USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_AssociateParticipantsReferredAccountListing]    Script Date: 08/26/2014 13:38:47 ******/
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

CREATE VIEW [dbo].[v_EAGLE_FEA_AssociateParticipantsReferredAccountListing]
AS
    -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  
--Associate Participants Referred Account Listing
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  
SELECT  ra.ProgramCode ProgramName ,
        CASE WHEN LEFT(ra.designatedAccountNumber , 1) = 'C'
             THEN 'ELECTRICITY'
             ELSE 'GAS'
        END ComodityType ,
        rp.AccountNumber ParticipantAccountNumber ,
        cp.Name_First + ' ' + cp.Name_Last ParticipantName ,
        ra.DesignatedAccountNumber DesignatedAccountNumber ,
        rr.ReferredAccountNumber ReferredAccountNumber ,
        cc.Name_First + ' ' + cc.Name_Last ReferredName ,
        CC.[app date] AppDate ,
        ROW_NUMBER() OVER ( PARTITION BY rp.AccountNumber ,
                            ra.DesignatedAccountNumber ORDER BY cc.[App Date] ) ReferredCount ,
        rr.AccountStatus ReferredAccountStatus ,
        cp.[Primary Email] ParticipantEMail ,
        CP.[Primary Phone] ParticipantPhone ,
        cp.[Billing City] ParticipantCity ,
        cp.[Billing State] ParticipantState ,
        cp.[Billing Zip] ParticipantZip
FROM    EAGLE.dbo.RPDesignatedAccount ra WITH ( NOLOCK )
INNER JOIN EAGLE.dbo.RPParticipant rp WITH ( NOLOCK ) ON rp.AccountNumber = ra.ParticipantAccountNumber
INNER JOIN EAGLE.dbo.RPReferredAccount rr WITH ( NOLOCK ) ON rr.DesignatedAccountNumber = ra.DesignatedAccountNumber
INNER JOIN EAGLE.dbo.tblCustomers cc WITH ( NOLOCK ) ON cc.[Customer Number] = rr.ReferredAccountNumber
INNER JOIN [Eagle].[dbo].[tblAssociatesAndHomesites] cp ON cp.[IA Number] = rp.AccountNumber
WHERE   rp.AccountStatus = 'Active'
        AND LEFT(rp.AccountNumber , 1) = 'A'
        AND ra.AccountStatus IN ( 'Active' , 'Pending' , 'PreVerify' )





GO


