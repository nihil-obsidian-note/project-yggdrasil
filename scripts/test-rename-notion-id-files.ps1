Describe 'rename-notion-id-files' {
    It 'rejects duplicate rename targets' {
        $map = @(
            [pscustomobject]@{ OldPath = '룩스테라\설정\검은 광기 3c2b3b5aa6f64078bff4fce6cc8d5194.md'; NewPath = '룩스테라\설정\검은 광기.md' },
            [pscustomobject]@{ OldPath = '룩스테라\설정\국가 11111111111111111111111111111111.md'; NewPath = '룩스테라\설정\국가.md' }
        )

        ($map.NewPath | Group-Object | Where-Object Count -gt 1).Count | Should Be 0
    }

    It 'removes trailing ids in markdown targets' {
        $sampleTarget = [Uri]::UnescapeDataString('%EA%B2%80%EC%9D%80%20%EA%B4%91%EA%B8%B0%203c2b3b5aa6f64078bff4fce6cc8d5194.md')
        ($sampleTarget -replace ' [0-9a-f]{32}(?=\.md$)', '') |
            Should Be '검은 광기.md'
    }
}
