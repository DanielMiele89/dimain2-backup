CREATE TABLE [Relational].[SFD_PostUploadAssessmentData_Member] (
    [MemberID]    INT IDENTITY (1, 1) NOT NULL,
    [FanID]       INT NOT NULL,
    [LionSendID]  INT NOT NULL,
    [OfferSlot]   INT NOT NULL,
    [IronOfferID] INT NOT NULL,
    CONSTRAINT [pk_MemberID] PRIMARY KEY CLUSTERED ([MemberID] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Relational].[SFD_PostUploadAssessmentData_Member]([FanID] ASC) WITH (FILLFACTOR = 95)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_LSID]
    ON [Relational].[SFD_PostUploadAssessmentData_Member]([LionSendID] ASC) WITH (FILLFACTOR = 95)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_IOID]
    ON [Relational].[SFD_PostUploadAssessmentData_Member]([IronOfferID] ASC) WITH (FILLFACTOR = 95)
    ON [Warehouse_Indexes];

