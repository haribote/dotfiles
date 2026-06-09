#!/usr/bin/env bash
set -euo pipefail

# Usage: ./fetch-unresolved-threads.sh <PR_NUMBER>
# Fetches unresolved review threads from a GitHub PR via GraphQL API.
# Requires: gh (authenticated), jq

PR_NUMBER="${1:?Usage: $0 <PR_NUMBER>}"

OWNER="$(gh repo view --json owner -q '.owner.login')"
REPO="$(gh repo view --json name -q '.name')"

RESPONSE="$(gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        pageInfo { hasNextPage }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 10) {
            pageInfo { hasNextPage }
            nodes {
              id
              databaseId
              author { login }
              body
              createdAt
            }
          }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F number="$PR_NUMBER")"

# Check for GraphQL errors
if echo "$RESPONSE" | jq -e '.errors // empty | length > 0' > /dev/null 2>&1; then
  echo "GraphQL error:" >&2
  echo "$RESPONSE" | jq '.errors' >&2
  exit 1
fi

# Check for null pullRequest (invalid PR number or no access)
if echo "$RESPONSE" | jq -e '.data.repository.pullRequest == null' > /dev/null 2>&1; then
  echo "Error: PR #${PR_NUMBER} not found or not accessible." >&2
  exit 1
fi

# Warn if results are truncated
if echo "$RESPONSE" | jq -e '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage' > /dev/null 2>&1; then
  echo "Warning: More than 100 review threads exist. Results are truncated." >&2
fi

echo "$RESPONSE" | jq '[
  .data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved == false)
  | {
      threadId: .id,
      outdated: .isOutdated,
      path: .path,
      line: .line,
      firstComment: {
        databaseId: .comments.nodes[0].databaseId,
        author: .comments.nodes[0].author.login,
        body: .comments.nodes[0].body
      },
      replies: [.comments.nodes[1:][] | {author: .author.login, body: .body}]
    }
]'
