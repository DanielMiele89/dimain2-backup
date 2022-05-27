CREATE TABLE [Relational].[ROC_CampaignHistory] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [FanID]             INT          NOT NULL,
    [PartnerID]         INT          NOT NULL,
    [IronOfferID]       INT          NOT NULL,
    [IsControl]         BIT          NOT NULL,
    [ClientServicesRef] VARCHAR (20) NULL,
    [SegmentID]         INT          NOT NULL,
    [WaveDatesID]       INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

