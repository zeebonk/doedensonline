require 'test_helper'

class RoutesTest < ActionDispatch::IntegrationTest
  # Root

  test "root" do
    assert_routing '/', controller: 'home', action: 'index'
  end

  # Home / auth

  test "GET /sign_in" do
    assert_routing '/sign_in', controller: 'home', action: 'sign_in'
  end

  test "GET /sign_out" do
    assert_routing '/sign_out', controller: 'home', action: 'sign_out'
  end

  test "POST /home/authenticate" do
    assert_routing({ method: :post, path: '/home/authenticate' },
                   controller: 'home', action: 'authenticate')
  end

  test "POST /home/destroy_session" do
    assert_routing({ method: :post, path: '/home/destroy_session' },
                   controller: 'home', action: 'destroy_session')
  end

  test "GET /home/password_forgotten" do
    assert_routing '/home/password_forgotten',
                   controller: 'home', action: 'password_forgotten'
  end

  test "POST /home/reset_password" do
    assert_routing({ method: :post, path: '/home/reset_password' },
                   controller: 'home', action: 'reset_password')
  end

  # News

  test "GET /news" do
    assert_routing '/news', controller: 'news', action: 'index'
  end

  test "GET /news/page/:page_number" do
    assert_routing '/news/page/2',
                   controller: 'news', action: 'page', page_number: '2'
  end

  test "GET /news/add" do
    assert_routing '/news/add', controller: 'news', action: 'add'
  end

  test "POST /news/create" do
    assert_routing({ method: :post, path: '/news/create' },
                   controller: 'news', action: 'create')
  end

  test "PATCH /news/update" do
    assert_routing({ method: :patch, path: '/news/update' },
                   controller: 'news', action: 'update')
  end

  test "POST /news/destroy" do
    assert_routing({ method: :post, path: '/news/destroy' },
                   controller: 'news', action: 'destroy')
  end

  test "POST /news/create_comment" do
    assert_routing({ method: :post, path: '/news/create_comment' },
                   controller: 'news', action: 'create_comment')
  end

  test "PATCH /news/update_comment" do
    assert_routing({ method: :patch, path: '/news/update_comment' },
                   controller: 'news', action: 'update_comment')
  end

  test "POST /news/destroy_comment" do
    assert_routing({ method: :post, path: '/news/destroy_comment' },
                   controller: 'news', action: 'destroy_comment')
  end

  test "GET /news/:id/remove" do
    assert_routing '/news/1/remove',
                   controller: 'news', action: 'remove', id: '1'
  end

  test "GET /news/:id/edit" do
    assert_routing '/news/1/edit',
                   controller: 'news', action: 'edit', id: '1'
  end

  test "GET /news/:id/add_comment" do
    assert_routing '/news/1/add_comment',
                   controller: 'news', action: 'add_comment', id: '1'
  end

  test "GET /news/edit_comment/:id" do
    assert_routing '/news/edit_comment/1',
                   controller: 'news', action: 'edit_comment', id: '1'
  end

  test "GET /news/remove_comment/:id" do
    assert_routing '/news/remove_comment/1',
                   controller: 'news', action: 'remove_comment', id: '1'
  end

  test "GET /news/:id" do
    assert_routing '/news/1',
                   controller: 'news', action: 'view', id: '1'
  end

  # Photo albums -custom routes

  test "GET /photo_albums/:id/remove" do
    assert_routing '/photo_albums/1/remove',
                   controller: 'photo_albums', action: 'remove', id: '1'
  end

  test "GET /photo_albums/page/:page_number" do
    assert_routing '/photo_albums/page/2',
                   controller: 'photo_albums', action: 'page', page_number: '2'
  end

  test "GET /photo_albums/:id/manage_pictures" do
    assert_routing '/photo_albums/1/manage_pictures',
                   controller: 'photo_albums', action: 'manage_pictures', id: '1'
  end

  test "POST /photo_albums/add_picture" do
    assert_routing({ method: :post, path: '/photo_albums/add_picture' },
                   controller: 'photo_albums', action: 'add_picture')
  end

  test "POST /photo_albums/destroy_many_pictures" do
    assert_routing({ method: :post, path: '/photo_albums/destroy_many_pictures' },
                   controller: 'photo_albums', action: 'destroy_many_pictures')
  end

  test "POST /photo_album_pictures/destroy_many" do
    assert_routing({ method: :post, path: '/photo_album_pictures/destroy_many' },
                   controller: 'photo_album_pictures', action: 'destroy_many')
  end

  # Settings

  test "GET /settings" do
    assert_routing '/settings', controller: 'settings', action: 'index'
  end

  test "GET /settings/profile" do
    assert_routing '/settings/profile', controller: 'settings', action: 'profile'
  end

  test "GET /settings/password" do
    assert_routing '/settings/password', controller: 'settings', action: 'password'
  end

  test "GET /settings/notifications" do
    assert_routing '/settings/notifications', controller: 'settings', action: 'notifications'
  end

  test "PATCH /settings/update_profile" do
    assert_routing({ method: :patch, path: '/settings/update_profile' },
                   controller: 'settings', action: 'update_profile')
  end

  test "PATCH /settings/update_password" do
    assert_routing({ method: :patch, path: '/settings/update_password' },
                   controller: 'settings', action: 'update_password')
  end

  test "PATCH /settings/update_notifications" do
    assert_routing({ method: :patch, path: '/settings/update_notifications' },
                   controller: 'settings', action: 'update_notifications')
  end

  # RESTful resources -users

  test "GET /users" do
    assert_routing '/users', controller: 'users', action: 'index'
  end

  test "GET /users/new" do
    assert_routing '/users/new', controller: 'users', action: 'new'
  end

  test "POST /users" do
    assert_routing({ method: :post, path: '/users' },
                   controller: 'users', action: 'create')
  end

  test "GET /users/:id" do
    assert_routing '/users/1', controller: 'users', action: 'show', id: '1'
  end

  test "GET /users/:id/edit" do
    assert_routing '/users/1/edit', controller: 'users', action: 'edit', id: '1'
  end

  test "PUT /users/:id" do
    assert_routing({ method: :put, path: '/users/1' },
                   controller: 'users', action: 'update', id: '1')
  end

  test "DELETE /users/:id" do
    assert_routing({ method: :delete, path: '/users/1' },
                   controller: 'users', action: 'destroy', id: '1')
  end

  # RESTful resources -photo_albums

  test "GET /photo_albums" do
    assert_routing '/photo_albums', controller: 'photo_albums', action: 'index'
  end

  test "GET /photo_albums/new" do
    assert_routing '/photo_albums/new', controller: 'photo_albums', action: 'new'
  end

  test "POST /photo_albums" do
    assert_routing({ method: :post, path: '/photo_albums' },
                   controller: 'photo_albums', action: 'create')
  end

  test "GET /photo_albums/:id" do
    assert_routing '/photo_albums/1',
                   controller: 'photo_albums', action: 'show', id: '1'
  end

  test "GET /photo_albums/:id/edit" do
    assert_routing '/photo_albums/1/edit',
                   controller: 'photo_albums', action: 'edit', id: '1'
  end

  test "PUT /photo_albums/:id" do
    assert_routing({ method: :put, path: '/photo_albums/1' },
                   controller: 'photo_albums', action: 'update', id: '1')
  end

  test "DELETE /photo_albums/:id" do
    assert_routing({ method: :delete, path: '/photo_albums/1' },
                   controller: 'photo_albums', action: 'destroy', id: '1')
  end

  # RESTful resources -photo_album_pictures

  test "GET /photo_album_pictures" do
    assert_routing '/photo_album_pictures',
                   controller: 'photo_album_pictures', action: 'index'
  end

  test "GET /photo_album_pictures/new" do
    assert_routing '/photo_album_pictures/new',
                   controller: 'photo_album_pictures', action: 'new'
  end

  test "POST /photo_album_pictures" do
    assert_routing({ method: :post, path: '/photo_album_pictures' },
                   controller: 'photo_album_pictures', action: 'create')
  end

  test "GET /photo_album_pictures/:id" do
    assert_routing '/photo_album_pictures/1',
                   controller: 'photo_album_pictures', action: 'show', id: '1'
  end

  test "GET /photo_album_pictures/:id/edit" do
    assert_routing '/photo_album_pictures/1/edit',
                   controller: 'photo_album_pictures', action: 'edit', id: '1'
  end

  test "PUT /photo_album_pictures/:id" do
    assert_routing({ method: :put, path: '/photo_album_pictures/1' },
                   controller: 'photo_album_pictures', action: 'update', id: '1')
  end

  test "DELETE /photo_album_pictures/:id" do
    assert_routing({ method: :delete, path: '/photo_album_pictures/1' },
                   controller: 'photo_album_pictures', action: 'destroy', id: '1')
  end

  # RESTful resources -photo_album_comments (with custom member route)

  test "GET /photo_album_comments" do
    assert_routing '/photo_album_comments',
                   controller: 'photo_album_comments', action: 'index'
  end

  test "GET /photo_album_comments/new" do
    assert_routing '/photo_album_comments/new',
                   controller: 'photo_album_comments', action: 'new'
  end

  test "POST /photo_album_comments" do
    assert_routing({ method: :post, path: '/photo_album_comments' },
                   controller: 'photo_album_comments', action: 'create')
  end

  test "GET /photo_album_comments/:id" do
    assert_routing '/photo_album_comments/1',
                   controller: 'photo_album_comments', action: 'show', id: '1'
  end

  test "GET /photo_album_comments/:id/edit" do
    assert_routing '/photo_album_comments/1/edit',
                   controller: 'photo_album_comments', action: 'edit', id: '1'
  end

  test "PUT /photo_album_comments/:id" do
    assert_routing({ method: :put, path: '/photo_album_comments/1' },
                   controller: 'photo_album_comments', action: 'update', id: '1')
  end

  test "DELETE /photo_album_comments/:id" do
    assert_routing({ method: :delete, path: '/photo_album_comments/1' },
                   controller: 'photo_album_comments', action: 'destroy', id: '1')
  end

  test "GET /photo_album_comments/:id/remove" do
    assert_routing '/photo_album_comments/1/remove',
                   controller: 'photo_album_comments', action: 'remove', id: '1'
  end
end
