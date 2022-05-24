CREATE TABLE [zion].[NominatedRedeemMember] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [RedeemID]    INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [StartDate]   DATETIME NULL,
    [EndDate]     DATETIME NULL,
    [Date]        DATETIME CONSTRAINT [DF_NominatedRedeemMember_Date] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_NominatedRedeemMember] PRIMARY KEY CLUSTERED ([ID] ASC)
);

