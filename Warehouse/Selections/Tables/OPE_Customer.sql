CREATE TABLE [Selections].[OPE_Customer] (
    [ID]           INT    IDENTITY (1, 1) NOT NULL,
    [FanID]        INT    NULL,
    [CompositeID]  BIGINT NULL,
    [RandomNumber] BIGINT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_CompIDRandNo]
    ON [Selections].[OPE_Customer]([CompositeID] ASC)
    INCLUDE([RandomNumber]);

