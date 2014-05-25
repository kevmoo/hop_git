library hop_git.test;

import 'dart:async';
import 'dart:io';

import 'package:git/git.dart';
import 'package:bot_io/bot_io.dart';
import 'package:hop/hop_core.dart';
import 'package:hop_git/hop_git.dart';
import 'package:unittest/unittest.dart';

import 'test_util.dart';

const _MASTER_BRANCH = 'master';
const _TEST_BRANCH = 'targetBranch';

const _SOURCE_DIR_MAP = const {
  'file.txt': 'file contents',
  'docs_dir': const {
    'doc.txt': 'the doc'
  }
};

const _TEST_CONTENT_2 = const {
  'file2.txt': 'file 2 contents',
  'file3.txt': 'file 3 contents'
};

const _TEST_CONTENT_3 = const {
  'file4.txt': 'file 4 contents',
  'file5.txt': 'file 5 contents',
  'docs_dir': const {
    'doc2.txt': 'the other doc'
  },
  'foo-dir': const {
    'foo_file.txt': 'full of foo'
  }
};


void main() {
  test('create branch from dir', () => TempDir.then(_testCreateBranch));
}

Future _testCreateBranch(Directory dir) {

  GitDir gitDir;

  return EntityPopulater.populate(dir.path, _SOURCE_DIR_MAP, leaveExistingDirs: true)
      .then((Directory value) {
        assert(value.path == dir.path);

        // new we're populated.
    // now make this a git dir
    return GitDir.init(dir, allowContent: true);
  })
  .then((GitDir value) {
    gitDir = value;

    // running now should still fail...no branch created
    final task = _createBranchTask(gitDir.path.toString());
    return runTaskInTestRunner(task);
  })
  .then((RunResult rr) {
    // yup, running here should cause an exception
    expect(rr, RunResult.EXCEPTION);

    // local branch count should be 0
    return gitDir.getBranchNames();
  })
  .then((List<String> branches) {
    expect(branches, isEmpty);

    // now add all files to staging
    return gitDir.runCommand(['add', '.', '--verbose']);
  })
  .then((_) {
    // now commit 'em!
    return gitDir.runCommand(['commit', '--verbose', '-am', 'first commit!']);
  })
  .then((ProcessResult pr) {
    // local branch count should be 1
    return gitDir.getBranchNames();
  })
  .then((List<String> branches) {
    expect(branches, hasLength(1));
    expect(branches, unorderedEquals([_MASTER_BRANCH]));

    // now, create branch should work great
    // running now should still fail...no branch created
    final task = _createBranchTask(gitDir.path.toString());
    return runTaskInTestRunner(task);
  })
  .then((RunResult rr) {
    // yup, running here should work great
    expect(rr, RunResult.SUCCESS);

    // local branch count should be 2
    return gitDir.getBranchNames();
  })
  .then((List<String> branches) {
    expect(branches, hasLength(2));
    expect(branches, unorderedEquals([_MASTER_BRANCH, _TEST_BRANCH]));

    // each branch should have 1 commit now
    return Future.wait([
                        gitDir.getCommitCount(_MASTER_BRANCH),
                        gitDir.getCommitCount(_TEST_BRANCH)
                        ]);

  })
  .then((List<int> counts) {
    expect(counts, hasLength(2));
    expect(counts[0], 1);
    expect(counts[1], 1);

    // populate the temp dir.
    return EntityPopulater.populate(dir.path, _TEST_CONTENT_2, leaveExistingDirs: true);
  })
  .then((_) {
    // now add all files to staging
    return gitDir.runCommand(['add', '.', '--verbose']);
  })
  .then((_) {
    // now commit 'em!
    return gitDir.runCommand(['commit', '--verbose', '-am', '2nd commit!']);
  })
  .then((_) {

    // now, create branch should work great
    // running now should still fail...no branch created
    final task = _createBranchTask(gitDir.path.toString());
    return runTaskInTestRunner(task);
  })
  .then((RunResult rr) {
    // yup, running here should work great
    expect(rr, RunResult.SUCCESS);


    // each branch should have 2 and 1 commits now
    return Future.wait([
                        gitDir.getCommitCount(_MASTER_BRANCH),
                        gitDir.getCommitCount(_TEST_BRANCH)
                        ]);

  })
  .then((List<int> counts) {
    expect(counts, hasLength(2));
    expect(counts[0], 2);
    expect(counts[1], 1, reason: 'should only have 1 commit here still');
  })
  .then((_) {
    // populate the temp dir.
    return EntityPopulater.populate(dir.path, _TEST_CONTENT_3, leaveExistingDirs: true);
  })
  .then((_) {
    // now add all files to staging
    return gitDir.runCommand(['add', '.', '--verbose']);
  })
  .then((_) {
    // now commit 'em!
    return gitDir.runCommand(['commit', '--verbose', '-am', '3rd commit!']);
  })
  .then((_) {

    // now, create branch should work great
    // running now should still fail...no branch created
    final task = _createBranchTask(gitDir.path.toString());
    return runTaskInTestRunner(task);
  })
  .then((RunResult rr) {
    // yup, running here should work great
    expect(rr, RunResult.SUCCESS);

    // each branch should have 3 and 1 commits now
    return Future.wait([
                        gitDir.getCommitCount(_MASTER_BRANCH),
                        gitDir.getCommitCount(_TEST_BRANCH)
                        ]);

  })
  .then((List<int> counts) {
    expect(counts, hasLength(2));
    expect(counts[0], 3);
    expect(counts[1], 2, reason: 'content in docs changed. We have 2 commits now');
  });
}

Task _createBranchTask(String workingDir) =>
  getBranchForDirTask(_MASTER_BRANCH, 'docs_dir', _TEST_BRANCH,
          workingDir: workingDir);
