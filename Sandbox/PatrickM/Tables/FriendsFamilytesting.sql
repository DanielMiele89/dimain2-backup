CREATE TABLE [PatrickM].[FriendsFamilytesting] (
    [email]       NVARCHAR (100) NOT NULL,
    [fanid]       INT            NOT NULL,
    [SourceUID]   VARCHAR (20)   NULL,
    [CompositeID] BIGINT         NULL
);


GO
CREATE CLUSTERED INDEX [FANID]
    ON [PatrickM].[FriendsFamilytesting]([fanid] ASC);

