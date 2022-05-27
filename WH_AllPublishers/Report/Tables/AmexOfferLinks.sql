CREATE TABLE [Report].[AmexOfferLinks] (
    [ID]                              INT          IDENTITY (1, 1) NOT NULL,
    [OfferCode_PreviouslyAmexOfferID] VARCHAR (10) NULL,
    [LinkedOfferID]                   INT          NULL,
    CONSTRAINT [PK__AmexOffe__3214EC2747425503] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Report_AmexOfferLinks_AmexOfferID_LinkedOfferID]
    ON [Report].[AmexOfferLinks]([OfferCode_PreviouslyAmexOfferID] ASC, [LinkedOfferID] ASC);

