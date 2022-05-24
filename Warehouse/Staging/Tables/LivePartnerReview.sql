CREATE TABLE [Staging].[LivePartnerReview] (
    [LivePartnerReviewID] INT           IDENTITY (1, 1) NOT NULL,
    [MID]                 VARCHAR (50)  NOT NULL,
    [Narrative]           VARCHAR (22)  NOT NULL,
    [Address]             VARCHAR (18)  NOT NULL,
    [MCC]                 VARCHAR (4)   NOT NULL,
    [MCCDesc]             VARCHAR (100) NOT NULL,
    [BrandMIDID]          INT           NOT NULL,
    [CombinationReviewID] INT           NULL,
    CONSTRAINT [PK_LivePartnerReview] PRIMARY KEY CLUSTERED ([LivePartnerReviewID] ASC),
    CONSTRAINT [FK_LivePartnerReview_BrandMID] FOREIGN KEY ([BrandMIDID]) REFERENCES [Relational].[BrandMID] ([BrandMIDID])
);

