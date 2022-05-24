CREATE TABLE [zion].[NominatedRedeemMember] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [RedeemID]    INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [StartDate]   DATETIME NULL,
    [EndDate]     DATETIME NULL,
    [Date]        DATETIME CONSTRAINT [DF_NominatedRedeemMember_Date] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_NominatedRedeemMember] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[zion].[NominatedRedeemMember] TO [gas]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[zion].[NominatedRedeemMember] TO [DataMart]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[zion].[NominatedRedeemMember] TO [DataMart]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[zion].[NominatedRedeemMember] TO [DataMart]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[zion].[NominatedRedeemMember] TO [DataMart]
    AS [dbo];

