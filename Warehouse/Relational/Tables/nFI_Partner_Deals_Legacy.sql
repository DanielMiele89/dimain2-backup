CREATE TABLE [Relational].[nFI_Partner_Deals_Legacy] (
    [ID]           INT            NOT NULL,
    [ClubID]       INT            NULL,
    [PartnerID]    INT            NULL,
    [IntroducedBy] VARCHAR (100)  NULL,
    [ManagedBy]    VARCHAR (100)  NULL,
    [CurrentDeal]  INT            NOT NULL,
    [StartDate]    DATE           NULL,
    [EndDate]      DATE           NULL,
    [Cashback]     DECIMAL (5, 4) NULL,
    [Publisher]    DECIMAL (5, 4) NULL,
    [Reward]       DECIMAL (5, 4) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [i_nFI_Partner_Deals_PID_CID_ED]
    ON [Relational].[nFI_Partner_Deals_Legacy]([PartnerID] ASC, [ClubID] ASC, [EndDate] ASC)
    INCLUDE([StartDate]);

