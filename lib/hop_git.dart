library hop_git;

import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:bot/bot.dart';
import 'package:git/git.dart';
import 'package:hop/hop_core.dart';

/// Creates a [Task] which creates and populates a branch with [sourceDir].
///
/// The contents of [sourceDir] on the [sourceBranch] are used to create or
/// update [targetBranch].
///
/// This task wraps [branchForDir] and provides a description.
Task getBranchForDirTask(String sourceBranch, String sourceDir,
                         String targetBranch, {String workingDir}) {
  requireArgumentNotNullOrEmpty(sourceBranch, 'sourceBranch');
  requireArgumentNotNullOrEmpty(sourceDir, 'sourceDir');
  requireArgumentNotNullOrEmpty(targetBranch, 'targetBranch');

  final description = 'Commit the tree for dir "$sourceDir" in branch'
      ' "$sourceBranch" and create/update branch "$targetBranch" with the new commit';

  return new Task((ctx) =>
      branchForDir(ctx, sourceBranch, sourceDir, targetBranch, workingDir: workingDir),
      description: description);
}


/// Creates and populates a branch with [sourceDir].
///
/// The contents of [sourceDir] on the [sourceBranch] are used to create or
/// update [targetBranch].
///
/// [getBranchForDirTask] wraps this into a [Task] and provides a description.
Future branchForDir(TaskContext ctx, String sourceBranch, String sourceDir,
    String targetBranch, {String workingDir}) {

  if (workingDir == null) {
    workingDir = p.current;
  }

  GitDir gitDir;

  String sourceDirTreeSha;
  String commitMsg;

  return GitDir.fromExisting(workingDir)
      .then((GitDir value) {
        gitDir = value;

        return gitDir.lsTree(sourceBranch, subTreesOnly: true, path: sourceDir);
      })
      .then((List<TreeEntry> entries) {
        assert(entries.length <= 1);
        if(entries.isEmpty) {
          throw 'Could not find a matching dir on the provided branch';
        }

        final tree = entries.single;

        sourceDirTreeSha = tree.sha;

        // get the commit SHA for the source branch for the commit MSG
        return gitDir.getBranchReference(sourceBranch);
      })
      .then((BranchReference sourceBranchRef) {
        final sourceBranchCommitShortSha = sourceBranchRef.sha.substring(0, 8);
        commitMsg = 'Contents of $sourceDir from commit $sourceBranchCommitShortSha';

        return gitDir.createOrUpdateBranch(targetBranch, sourceDirTreeSha, commitMsg);
      })
      .then((String newCommitSha) {
        if(newCommitSha == null) {
          ctx.fine('There have been no changes to "$sourceDir" since the last commit');
        } else {
          ctx.info("Branch '$targetBranch' is now at commit $newCommitSha");
        }
      });
}
