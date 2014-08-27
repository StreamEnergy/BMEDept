USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_100_NODATE]    Script Date: 08/26/2014 13:37:02 ******/
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


CREATE VIEW [dbo].[v_EAGLE_FEA_100_NODATE]
AS
    SELECT  AA.ProgramName ,
            AA.ComodityType ,
            100 AS Percentage ,
            AA.ParticipantAccountNumber ,
            AA.ParticipantName ,
            AA.DesignatedAccountNumber ,
            AA.ReferredAccountNumber ,
            AA.ReferredName ,
            AA.AppDate ,
            AA.ReferredCount ,
            AA.ReferredAccountStatus ,
            AA.ParticipantEMail ,
            AA.ParticipantPhone ,
            AA.ParticipantCity ,
            AA.ParticipantState ,
            AA.ParticipantZip
    FROM    StreamInternal.dbo.[v_EAGLE_FEA_AssociateParticipantsReferredAccountListing] AA
            WITH ( NOLOCK )
    INNER JOIN ( SELECT ZZ.ParticipantAccountNumber
                 FROM   StreamInternal.dbo.[v_EAGLE_FEA_AssociateParticipantsReferredAccountListing] ZZ
                        WITH ( NOLOCK ) 
		--WHERE		ZZ.AppDate						> '2013-09-28' 
		-- WHERE		ZZ.ReferredAccountStatus		= 'Active' 
                 GROUP BY ZZ.ParticipantAccountNumber ,
                        ZZ.ProgramName
                 HAVING MAX(ReferredCount) > 14
                        AND ZZ.ProgramName = 'STANDARD15'
               ) ST ON AA.ParticipantAccountNumber = ST.ParticipantAccountNumber

-- WHERE	AA.AppDate					> '2013-09-28' 
    WHERE   AA.ReferredAccountStatus = 'Active'
            AND AA.ProgramName = 'STANDARD15'
    UNION
    SELECT  AA.ProgramName ,
            AA.ComodityType ,
            100 AS Percentage ,
            AA.ParticipantAccountNumber ,
            AA.ParticipantName ,
            AA.DesignatedAccountNumber ,
            AA.ReferredAccountNumber ,
            AA.ReferredName ,
            AA.AppDate ,
            AA.ReferredCount ,
            AA.ReferredAccountStatus ,
            AA.ParticipantEMail ,
            AA.ParticipantPhone ,
            AA.ParticipantCity ,
            AA.ParticipantState ,
            AA.ParticipantZip
    FROM    StreamInternal.dbo.[v_EAGLE_FEA_AssociateParticipantsReferredAccountListing] AA
            WITH ( NOLOCK )
    INNER JOIN ( SELECT ZZ.ParticipantAccountNumber
                 FROM   StreamInternal.dbo.[v_EAGLE_FEA_AssociateParticipantsReferredAccountListing] ZZ
                        WITH ( NOLOCK ) 
--		WHERE		ZZ.AppDate						> '2013-09-28' 
                 WHERE  ZZ.ReferredAccountStatus = 'Active'
                 GROUP BY ZZ.ParticipantAccountNumber ,
                        ZZ.ProgramName
                 HAVING MAX(ReferredCount) > 11
                        AND ZZ.ProgramName = 'STANDARD12'
               ) ST ON AA.ParticipantAccountNumber = ST.ParticipantAccountNumber

-- WHERE	AA.AppDate					> '2013-09-28' 
-- WHERE		AA.ReferredAccountStatus	= 'Active' 
                       AND AA.ProgramName = 'STANDARD12'
    UNION
    SELECT  AA.ProgramName ,
            AA.ComodityType ,
            100 AS Percentage ,
            AA.ParticipantAccountNumber ,
            AA.ParticipantName ,
            AA.DesignatedAccountNumber ,
            AA.ReferredAccountNumber ,
            AA.ReferredName ,
            AA.AppDate ,
            AA.ReferredCount ,
            AA.ReferredAccountStatus ,
            AA.ParticipantEMail ,
            AA.ParticipantPhone ,
            AA.ParticipantCity ,
            AA.ParticipantState ,
            AA.ParticipantZip
    FROM    StreamInternal.dbo.[v_EAGLE_FEA_CustomerParticipantsReferredAccountListing] AA
            WITH ( NOLOCK )
    INNER JOIN ( SELECT ZZ.ParticipantAccountNumber
                 FROM   StreamInternal.dbo.[v_EAGLE_FEA_CustomerParticipantsReferredAccountListing] ZZ
                        WITH ( NOLOCK ) 
-- 		WHERE		ZZ.AppDate						> '2013-09-28' 
--		WHERE			ZZ.ReferredAccountStatus		= 'Active' 
                 GROUP BY ZZ.ParticipantAccountNumber ,
                        ZZ.ProgramName
                 HAVING MAX(ReferredCount) > 14
                        AND ZZ.ProgramName = 'STANDARD15'
               ) ST ON AA.ParticipantAccountNumber = ST.ParticipantAccountNumber

-- WHERE	AA.AppDate					> '2013-09-28' 
-- WHERE		AA.ReferredAccountStatus	= 'Active' 
                       AND AA.ProgramName = 'STANDARD15'
    UNION
    SELECT  AA.ProgramName ,
            AA.ComodityType ,
            100 AS Percentage ,
            AA.ParticipantAccountNumber ,
            AA.ParticipantName ,
            AA.DesignatedAccountNumber ,
            AA.ReferredAccountNumber ,
            AA.ReferredName ,
            AA.AppDate ,
            AA.ReferredCount ,
            AA.ReferredAccountStatus ,
            AA.ParticipantEMail ,
            AA.ParticipantPhone ,
            AA.ParticipantCity ,
            AA.ParticipantState ,
            AA.ParticipantZip
    FROM    StreamInternal.dbo.[v_EAGLE_FEA_CustomerParticipantsReferredAccountListing] AA
            WITH ( NOLOCK )
    INNER JOIN ( SELECT ZZ.ParticipantAccountNumber
                 FROM   StreamInternal.dbo.[v_EAGLE_FEA_CustomerParticipantsReferredAccountListing] ZZ
                        WITH ( NOLOCK ) 
--		WHERE		ZZ.AppDate						> '2013-09-28' 
--		WHERE		ZZ.ReferredAccountStatus		= 'Active' 
                 GROUP BY ZZ.ParticipantAccountNumber ,
                        ZZ.ProgramName
                 HAVING MAX(ReferredCount) > 11
                        AND ZZ.ProgramName = 'STANDARD12'
               ) ST ON AA.ParticipantAccountNumber = ST.ParticipantAccountNumber

-- WHERE	AA.AppDate					> '2013-09-28' 
-- WHERE		AA.ReferredAccountStatus	= 'Active' 
                       AND AA.ProgramName = 'STANDARD12'














GO


