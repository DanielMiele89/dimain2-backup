CREATE TABLE [dbo].[SessionLock] (
    [SessionID]   VARCHAR (32) NOT NULL,
    [LockVersion] INT          DEFAULT ((0)) NOT NULL
);




GO
CREATE UNIQUE CLUSTERED INDEX [IDX_SessionLock]
    ON [dbo].[SessionLock]([SessionID] ASC);


GO
GRANT UPDATE
    ON OBJECT::[dbo].[SessionLock] TO [RSExecRole]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[SessionLock] TO [RSExecRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[dbo].[SessionLock] TO [RSExecRole]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[SessionLock] TO [RSExecRole]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[dbo].[SessionLock] TO [RSExecRole]
    AS [dbo];

