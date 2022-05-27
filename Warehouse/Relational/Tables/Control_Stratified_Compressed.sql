CREATE TABLE [Relational].[Control_Stratified_Compressed] (
    [id]                INT          IDENTITY (1, 1) NOT NULL,
    [CinID]             INT          NULL,
    [FanID]             INT          NULL,
    [PartnerID]         INT          NULL,
    [MinMonthID]        INT          NOT NULL,
    [MaxMonthID]        INT          NOT NULL,
    [PartnerGroupID]    INT          NULL,
    [ClientServicesRef] VARCHAR (40) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE),
    CONSTRAINT [unq_PFM2] UNIQUE NONCLUSTERED ([FanID] ASC, [PartnerID] ASC, [PartnerGroupID] ASC, [ClientServicesRef] ASC, [MinMonthID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);




GO
CREATE NONCLUSTERED INDEX [idx_Monthid]
    ON [Relational].[Control_Stratified_Compressed]([MinMonthID] ASC, [MaxMonthID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [idx_Control]
    ON [Relational].[Control_Stratified_Compressed]([FanID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
GRANT ALTER
    ON OBJECT::[Relational].[Control_Stratified_Compressed] TO [RetailerMonthlyReportUser]
    AS [dbo];

