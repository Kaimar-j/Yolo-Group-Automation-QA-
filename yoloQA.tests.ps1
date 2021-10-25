BeforeAll {
    $Script:headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add('Content-Type', 'application/json')
    $headers.Add('Accept', 'application/json')
    $headers.Add("Authorization", "Bearer 48a839dd7179ed9405c5f0a0a981a0701c384db7756ddea1e1dce4d913f867ec")
    $random_name = [System.IO.Path]::GetRandomFileName()
    $secondary_random_name = [System.IO.Path]::GetRandomFileName()
    $Script:name = "$($random_name.split('.')[0]) $($random_name.split('.')[1])"
    $Script:secondary_name = "$($secondary_random_name.split('.')[0]) $($secondary_random_name.split('.')[1])"
    $Script:email = Get-Date -UFormat "$random_name@outlook.com"
    $Script:gender = "male"
    $Script:status = "active"
    $Script:post_title = -join ((65..90) + (97..122) | Get-Random -Count 50 | ForEach-Object { [char]$_ })
    $Script:post_body = -join ((65..90) + (97..122) | Get-Random -Count 50 | ForEach-Object { [char]$_ })
    $Script:comment_title = -join ((65..90) + (97..122) | Get-Random -Count 50 | ForEach-Object { [char]$_ })
    $Script:comment_body = -join ((65..90) + (97..122) | Get-Random -Count 50 | ForEach-Object { [char]$_ })
    $Script:todo_title = -join ((65..90) + (97..122) | Get-Random -Count 50 | ForEach-Object { [char]$_ })
    $Script:todo_due_on = "$(((Get-Date).AddDays((7)).ToString("yyyy-MM-ddTHH:mm:ss")))"
    $Script:todo_status = "Pending"
}

Describe 'PUT' {
    It "Create new user" {
        $user_body = [ordered]@{
            name   = $name
            gender = $gender
            email  = $email
            status = $status
        } | ConvertTo-Json -Compress -Depth 2

        $new_user_req = Invoke-RestMethod "https://gorest.co.in/public/v1/users" -Method POST -Headers $headers -Body $user_body
        $user_id = $new_user_req.data.id
        $user_id | Should -BeGreaterThan 0
    }

    It "Create new post" {
        $user_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/users?name=$name" -Method GET -Headers $headers).data
        $post_body = [ordered]@{
            user_id = "$($user_data.id)"
            title   = $post_title
            body    = $post_body
        } | ConvertTo-Json -Compress -Depth 2

        $new_post_req = Invoke-RestMethod "https://gorest.co.in/public/v1/posts" -Method POST -Headers $headers -Body $post_body
        $post_id = $new_post_req.data.id
        $post_id | Should -BeGreaterThan 0
    }

    It "Add comment" {
        $user_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/users?name=$name" -Method GET -Headers $headers).data
        $post_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/posts?user_id=$($user_data.id)" -Method GET -Headers $headers).data
        $comment_body = [ordered]@{
            name    = $comment_title
            post_id = "$($post_data.id)"
            email   = $email
            body    = $comment_body
        } | ConvertTo-Json -Compress -Depth 2

        $new_comment_req = Invoke-RestMethod "https://gorest.co.in/public/v1/comments" -Method POST -Headers $headers -Body $comment_body
        $comment_id = $new_comment_req.data.id
        $comment_id | Should -BeGreaterThan 0
    }

    It "Create new TODO" {
        $user_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/users?name=$name" -Method GET -Headers $headers).data
        $todo_body = [ordered]@{
            user_id = $user_data.id
            title   = $todo_title
            due_on  = $todo_due_on
            status  = $todo_status
        } | ConvertTo-Json -Compress -Depth 2

        $new_todo_req = Invoke-RestMethod "https://gorest.co.in/public/v1/todos" -Method POST -Headers $headers -Body $todo_body
        $todo_id = $new_todo_req.data.id
        $todo_id | Should -BeGreaterThan 0
    }

    It "Create new user with missing email field" {
        try {
            $body = [ordered]@{
                name   = $name
                gender = $email
                status = $status
            } | ConvertTo-Json -Compress -Depth 2
            Invoke-RestMethod "https://gorest.co.in/public/v1/users" -Method POST -Headers $headers -Body $body -ErrorAction Continue
        }
        catch {
            $errors = $_
            $errors | Should -Not -BeNullOrEmpty
        }
    }

    It "Create new post without user_id field" {
        try {
            $post_body = [ordered]@{
                title = $post_title
                body  = $post_body
            } | ConvertTo-Json -Compress -Depth 2
            Invoke-RestMethod "https://gorest.co.in/public/v1/users" -Method POST -Headers $headers -Body $post_body -ErrorAction Continue
        }
        catch {
            $errors = $_
            $errors | Should -Not -BeNullOrEmpty
        }
    }

    It "Create new users using same email address" {
        try {
            $user_body = [ordered]@{
                name   = $name
                gender = $gender
                email  = $email
                status = $status
            } | ConvertTo-Json -Compress -Depth 2
            
            $user_body_secondary = [ordered]@{
                name   = $secondary_name
                gender = $gender
                email  = $email
                status = $status
            } | ConvertTo-Json -Compress -Depth 2
            Invoke-RestMethod "https://gorest.co.in/public/v1/users" -Method POST -Headers $headers -Body $user_body -ErrorAction Continue
            Invoke-RestMethod "https://gorest.co.in/public/v1/users" -Method POST -Headers $headers -Body $user_body_secondary -ErrorAction Continue
        }
        catch {
            $errors = $_
            $errors | Should -Not -BeNullOrEmpty
        }
    }

    It "Create user with invalid email address" {
        try {
            $user_body = [ordered]@{
                name   = $name
                gender = $gender
                email  = $($email.Replace("@", "@@"))
                status = $status
            } | ConvertTo-Json -Compress -Depth 5
            Invoke-RestMethod "https://gorest.co.in/public/v1/users" -Method POST -Headers $headers -Body $user_body -ErrorAction Continue
        }
        catch {
            $errors = $_
            $errors | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'GET' {
    It "Get all users" {
        $all_users = Invoke-RestMethod "https://gorest.co.in/public/v1/users" -Method GET -Headers $headers
        $all_users.data.Count | Should -BeGreaterThan 1
    }

    It "Get and check created user data" {
        $user_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/users?name=$name" -Method GET -Headers $headers).data
        $user_data.id | Should -BeGreaterThan 0
        $user_data.name | Should -Be $name
        $user_data.email | Should -Be $email
        $user_data.gender | Should -Be $gender
        $user_data.status | Should -Be $status
    }

    It "Created post" {
        $user_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/users?name=$name" -Method GET -Headers $headers).data
        $post_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/posts?user_id=$($user_data.id)" -Method GET -Headers $headers).data
        $post_data.user_id | Should -Be $user_data.id
        $post_data.title | Should -Be $post_title
        $post_data.body | Should -Be $post_body

    }

    It "Created comment" {
        $user_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/users?name=$name" -Method GET -Headers $headers).data
        $post_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/posts?user_id=$($user_data.id)" -Method GET -Headers $headers).data
        $comment_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/comments?post_id=$($post_data.id)" -Method GET -Headers $headers).data
        $comment_data.name | Should -Be $comment_title
        $comment_data.email | Should -Be $email
        $comment_data.body | Should -Be $comment_body
    }

    It "Created TODO" {
        $user_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/users?name=$name" -Method GET -Headers $headers).data
        $todo_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/todos?user_id=$($user_data.id)" -Method GET -Headers $headers).data
        $todo_data.user_id | Should -Be $user_data.id
        $todo_data.title | Should -Be $todo_title
        $todo_data.status | Should -Be $todo_status
    }


}

Describe 'DELETE' {
    It "Deletes user" {
        $user_data = (Invoke-RestMethod "https://gorest.co.in/public/v1/users?name=$name" -Method GET -Headers $headers).data
        $delete_request = Invoke-RestMethod "https://gorest.co.in/public/v1/users/$($user_data.id)" -Method DELETE -Headers $headers 
        $delete_request | Should -BeNullOrEmpty
    }
}

