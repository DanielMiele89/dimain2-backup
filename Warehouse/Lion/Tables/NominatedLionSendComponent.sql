CREATE TABLE [Lion].[NominatedLionSendComponent] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [LionSendID]  INT      NULL,
    [CompositeID] BIGINT   NOT NULL,
    [TypeID]      INT      NULL,
    [ItemRank]    INT      NULL,
    [ItemID]      INT      NULL,
    [StartDate]   DATETIME NULL,
    [EndDate]     DATETIME NULL,
    [Date]        DATETIME NULL,
    CONSTRAINT [PK_NominatedLionSendComponent] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE),
    CONSTRAINT [IUX_LSIDOfferCompRank] UNIQUE NONCLUSTERED ([LionSendID] ASC, [TypeID] ASC, [CompositeID] ASC, [ItemRank] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = ROW)
);


GO
GRANT SELECT
    ON OBJECT::[Lion].[NominatedLionSendComponent] TO [gas]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[Lion].[NominatedLionSendComponent] TO [DataMart]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Lion].[NominatedLionSendComponent] TO [DataMart]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Lion].[NominatedLionSendComponent] TO [DataMart]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Lion].[NominatedLionSendComponent] TO [DataMart]
    AS [dbo];

