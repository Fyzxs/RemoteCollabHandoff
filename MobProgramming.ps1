#
# I'm explicitly using Procedural Programming - Not Imperitive Programming.
#

<#

.SYNOPSIS
This is a simple Powershell script to simplify remote mobbing hand off.

.DESCRIPTION
The script will perform git commands to enable remote handoff without screen sharing issues

.EXAMPLE
mob start \t# start mobbing as typist
mob next \t# hand over to next typist
mob done \t# finishes the mobbing session
mob reset \t# resets the mob sessions. WARNING - DELETES FROM SERVER
mob help \t# prints this


.NOTES
A work in progress. Please provide feedback to quinn.gil@premera.com


.LINK
https://github.com/Fyzxs/mob

#>

$command = $Args[0]
$DebugPreference = "SilentlyContinue"
if($command -eq "Debug"){
    $command = $Args[1]
    $DebugPreference = "Continue"
}

$scriptName = $MyInvocation.MyCommand.Name
$mob_branch = "mob-session"
$source_branch = "master"

function Main{
    Print-Executing
    if(Is-Help){
        Command-Help
    } elseif(Is-Status) {
        Command-Status
    } elseif(Is-Reset) {
        Command-Reset
    } elseif(Is-Done) {
        Command-Done
    } elseif(Is-Next) {
        Command-Next
    } elseif(Is-Start) {
        Command-Start
        Command-Status
    } else{
        Command-Unknown
    }
}

#
# Status functionality
# 
function Is-Status{
    $command -eq "status"
}
function Command-Status{
    Print-Executing
    if(Is-Mobbing){
        Print-MobbingInProgress
        Git-Log-Summary
    } else {
        Print-NotMobbing
    }
}


#
# Reset functionality
#
function Is-Reset{
    ($command -eq "reset") -or ($command -eq "r")
}

function Command-Reset{
    Git-Refresh
    Git-Checkout-SourceBranch
    
    if(Has-LocalMobBranch){
        Print-Debug "Removing local mobbing branch"
        Git-Delete-LocalMobBranch
    }

    if(Has-RemoteMobBranch){
        Print-Debug "Removing server mobbing branch"
        Git-Delete-RemoteMobBranch
    }
}

#
# Done functionality
#
function Is-Done{
    ($command -eq "done") -or ($command -eq "d")
}
function Command-Done{
     if(-Not $(Is-Mobbing)){
        Print-NotMobbing
    } elseif(Has-RemoteMobBranch){
        if(Is-ThingsToCommit){
            Git-Track-AllFiles
            Git-Commit-WIP
        }

        Git-Update-RemoteMobBranch
        Git-Checkout-SourceBranch
        Git-Merge-SourceBranch
        Git-Merge-MobBranch
        Git-Delete-LocalMobBranch
        Git-Delete-RemoteMobBranch

        Git-Diff-CachedChange
        Print-Info "Create Actual Commit Entry ('git commit -m `"describe the change`")"

    } else{
        Git-Checkout-SourceBranch
        Git-Delete-LocalMobBranch

        Print-Info "Mob Sessions was already ended"
    }
}

#
# Next functionality
#
function Is-Next{
    ($command -eq "next") -or ($command -eq "n")
}
function Command-Next{
    Print-Executing
    if(Is-NotMobbing){
        Print-NotMobbing
    } elseif(Is-NothingToCommit){
        Print-Info "nothing has been done, so nothing to commit"
    } else {
        Git-Prepare-Next
    }
}

#
# Start functionality
#
function Is-Start{
    ($command -eq "start") -or ($command -eq "s")
}
function Command-Start{
    if(Is-ThingsToCommit){
        Print-Info "Uncommitted Changes"
    } elseif((Has-LocalMobBranch) -and (Has-RemoteMobBranch)){ #Should Clean Up Branch
        Print-Info "rejoining Mob Session"
        
        Git-Refresh
        Git-Delete-LocalMobBranch
        Git-Checkout-MobBranch
        Git-Create-LocalMobBranch

    } elseif((Has-NoLocalMobBranch) -and (Has-NoRemoteMobBranch)){ #Should Create Branch
        Print-Info "Create $mob_branch from $source_branch"
        
        Git-Refresh
        Merge-SourceBranch

    } elseif((Has-NoLocalMobBranch) -and (Has-RemoteMobBranch)){ #Should Retrieve Branch
        Print-Info "joining mob Session"
        
        Git-Refresh
        Git-Checkout-MobBranch
        Git-Create-LocalMobBranch

    } elseif((Has-LocalMobBranch) -and (Has-NoRemoteMobBranch)){ #Should Refresh Local Branch
        Print-Info "purging local branch and starting new $mob_branch from $source_branch"
        
        Git-Refresh
        Git-Delete-LocalMobBranch
        Merge-SourceBranch

    }
}

#
# Help functionality
#
function Is-Help{
    ($command -eq "help") -or ($command -eq "h") -or ($([string]::IsNullOrWhitespace($command)))
}

function Command-Help{
    Print-Info "$scriptName Help Info"
    Print-Info "$scriptName [s]tart `t# start mobbing as typist"
    Print-Info "$scriptName [n]ext `t# hand over to next typist"
    Print-Info "$scriptName [d]one `t# finishes the mobbing session"
    Print-Info "$scriptName [r]eset `t# deletes local and remote mob branch"
    Print-Info "$scriptName status `t# current status"
    Print-Info "$scriptName [h]elp `t# prints this"
}

function Command-Unknown{
    Print-Executing
    Print-Info "Unknown Command [$command]"
    Command-Help
}

#
# Git
#
function Git-Invoke($argumentString){
    Print-Executing($argumentString)
    [string]$(Invoke-Expression("git $argumentString"))
}
function Is-NothingToCommit{
    (Git-Status).length -eq 0
}
function Is-ThingsToCommit{
    -Not (Is-NothingToCommit)
}
function Git-Prepare-Next{
    Git-Track-AllFiles
    Git-Commit-WIP
    Git-Diff-LastChange
    Git-Update-RemoteMobBranch
}

function Merge-SourceBranch{
    Git-Checkout-SourceBranch
    Git-Merge-SourceBranch
    Git-Create-LocalMobBranch
    Git-Checkout-MobBranch
    Git-Create-RemoteMobBranch
}

function Git-Create-RemoteMobBranch{Git-Update-RemoteMobBranch}

function Git-Refresh{Git-Invoke("fetch --prune")}
function Git-Track-AllFiles{Git-Invoke("add --all")}
function Git-Create-LocalMobBranch{Git-Invoke("branch $mob_branch")}
function Git-Delete-LocalMobBranch{Git-Invoke("branch -D $mob_branch")}
function Git-Checkout-MobBranch{Git-Invoke("checkout $mob_branch")}
function Git-Checkout-SourceBranch{Git-Invoke("checkout $source_branch")}
function Git-Commit-WIP{Git-Invoke("commit --message `"WIP in Mob Sessions`"")}
function Git-Diff-LastChange{Git-Invoke("diff HEAD^1 --stat")}
function Git-Diff-CachedChange{Git-Invoke("diff --cached --stat")}
function Git-Update-RemoteMobBranch{Git-Invoke("push --set-upstream --no-verify origin $mob_branch")}
function Git-Delete-RemoteMobBranch{Git-Invoke("push origin --delete $mob_branch")}
function Git-Merge-SourceBranch{Git-Invoke("merge origin/$source_branch --ff-only")}
function Git-Merge-MobBranch{Git-Invoke("merge --squash $mob_branch")}
function Git-Branches-All{Git-Invoke("branch --all")}
function Git-Status{Git-Invoke("status --short")}
function Git-Log-Summary{Git-Invoke("--no-pager log $source_branch..$mob_branch --pretty=format:'%h %cr <%an>' --abbrev-commit")}

function Is-Mobbing{
    (Git-Branches-All) -match "\* $mob_branch"
}
function Is-NotMobbing{
    -Not (Is-Mobbing)
}
function Has-LocalMobBranch{
    (Git-Branches-All) -match "  $mob_branch" -or $(Is-Mobbing)
}
function Has-NoLocalMobBranch{
    -Not (Has-LocalMobBranch)
}
function Has-RemoteMobBranch{
    (Git-Branches-All) -match "remotes/origin/$mob_branch"
}
function Has-NoRemoteMobBranch{
    -Not (Has-RemoteMobBranch)
}

#
# Print Methods
#
function Print-NotMobbing{
    Print-Info "you aren't mobbing right now"
}
function Print-MobbingInProgress{
    Print-Info "mobbing in progress"
}
function Print-Debug($msg){
    Write-Debug($msg)
}

function Print-Info($msg){
    Write-Host $msg
}
function Print-Error($msg){
    Write-Error $msg
}
function Print-Executing($arguments) {
    if($DebugPreference){
        $callStack = Get-PSCallStack
        if ($callStack.Count -gt 1) {
            'Executing function: {0} {1}' -f $callStack[1].FunctionName, $arguments
        }
    }
}

# Actually run the thing
Main
