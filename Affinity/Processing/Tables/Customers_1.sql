CREATE TABLE [Processing].[Customers] (
    [FanID]            INT            NOT NULL,
    [ProxyUserID]      VARBINARY (32) NULL,
    [CompositeID]      BIGINT         NULL,
    [ClubID]           INT            NULL,
    [PostcodeDistrict] VARCHAR (10)   NULL,
    [SourceUID]        VARCHAR (20)   NULL,
    [rw]               INT            NULL,
    [PostalArea]       VARCHAR (4)    NULL,
    [CINID]            INT            NULL,
    [Chksum]           INT            NULL,
    [isNew]            BIT            NULL,
    [CreatedDateTime]  DATETIME2 (7)  CONSTRAINT [DF_Processing_Customers_CreatedDateTime] DEFAULT (getdate()) NULL
);


GO
CREATE CLUSTERED INDEX [cx_FanID]
    ON [Processing].[Customers]([FanID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_ClubID_CompositeID]
    ON [Processing].[Customers]([ClubID] ASC, [CompositeID] ASC)
    INCLUDE([FanID], [ProxyUserID], [PostalArea], [SourceUID], [PostcodeDistrict]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_rw_CINID]
    ON [Processing].[Customers]([rw] ASC, [CINID] ASC)
    INCLUDE([FanID], [ProxyUserID], [PostalArea], [SourceUID], [PostcodeDistrict]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_Chksum]
    ON [Processing].[Customers]([CINID] ASC, [Chksum] ASC) WHERE ([CINID] IS NOT NULL) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Truncated transformed Fan table that has appropriate obfuscation columns along with the required, non-obfuscated version of columns.  Includes Customers on MyRewards that have ever AgreedTCs and any customers on selected nFIs', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Customers';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'FanID as found on the Fan table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'FanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The hash of the "FanID + 2384,SourceUID" with the comma included in the hash; this is for Client facing CustomerID', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'ProxyUserID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'CompositeID as found on the Fan table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'CompositeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ClubID as found on the Fan table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'ClubID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The Postcode District as found on Relational.Customer (e.g. SW17)', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'PostcodeDistrict';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The SourceUID as found on Fan', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'SourceUID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ROWNUMBER() split by SourceUID ORDER BY ClubID (to give 132 precedence) -- this is for cases when customers appear on both 132/138, to ensure a single match when joining to transactions', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'rw';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The PostalArea as found on Relational.Customer (e.g. SW)', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Customers', @level2type = N'COLUMN', @level2name = N'PostalArea';

