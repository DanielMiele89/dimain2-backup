CREATE PROC [WHB].[__RBS_LandingIronOffer_Load]
AS
INSERT INTO [Inbound].[RBS_IronOffer]([IronOfferID], [IronOfferName], [HydraOfferID], [StartDate], [EndDate], [PartnerID], [IsAboveTheLine], [AutoAddToNewRegistrants], [IsDefaultCollateral], [IsSignedOff], [AreEligibleMembersCommitted], [AreControlMembersCommitted], [IsTriggerOffer], [Continuation], [TopCashBackRate], [AboveBase], [Clubs], [CampaignType], [SegmentName], [ClubID])
SELECT 
	   io.[IronOfferID]
      ,io.[IronOfferName]
	  ,'' AS [HydraOfferID]
      ,[StartDate]
      ,[EndDate]
      ,io.[PartnerID]
      ,[IsAboveTheLine]
      ,[AutoAddToNewRegistrants]
      ,[IsDefaultCollateral]
      ,[IsSignedOff]
      ,[AreEligibleMembersCommitted]
      ,[AreControlMembersCommitted]
      ,[IsTriggerOffer]
      ,[Continuation]
      ,[TopCashBackRate]
      ,[AboveBase]
      ,io.[Clubs]
	  ,[CampaignType]
      ,ios.SegmentName AS SegmentName --Should this be ios.SuperSegmentName
	  ,CASE WHEN IO.[Clubs] = 'Natwest' THEN 132
			WHEN IO.[Clubs] = 'RBS' THEN 138
			ELSE Both.Club 
		END AS [ClubID]
  FROM [Warehouse].[Relational].[IronOffer] io
  --Should I do the below to spit out Clubs where it says Both into the individual ClubId
	LEFT JOIN (
				SELECT IronOfferID,Clubs,Club FROM [Warehouse].[Relational].[IronOffer]
				OUTER APPLY(
								SELECT 132 UNION SELECT 138 )O (Club)
				WHERE  [Clubs] = 'Both'
			) Both on Both.IronOfferID = io.IronOfferID
	LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] ios ON ios.IronOfferID = io.IronOfferID