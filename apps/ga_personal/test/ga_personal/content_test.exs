defmodule GaPersonal.ContentTest do
  use GaPersonal.DataCase, async: true

  alias GaPersonal.Content
  alias GaPersonal.Content.{BlogPost, Testimonial, FAQ}

  describe "blog_posts" do
    setup do
      trainer = insert(:trainer)
      %{trainer: trainer}
    end

    test "list_blog_posts/1 returns posts for trainer", %{trainer: trainer} do
      post = insert(:blog_post, trainer: trainer)
      assert [%BlogPost{id: id}] = Content.list_blog_posts(trainer.id)
      assert id == post.id
    end

    test "create_blog_post/1 with valid data", %{trainer: trainer} do
      attrs = %{
        trainer_id: trainer.id,
        title: "Fitness Tips",
        slug: "fitness-tips",
        content: "Here are some great fitness tips..."
      }

      assert {:ok, %BlogPost{title: "Fitness Tips"}} = Content.create_blog_post(attrs)
    end

    test "create_blog_post/1 with duplicate slug returns error", %{trainer: trainer} do
      insert(:blog_post, trainer: trainer, slug: "taken-slug")
      attrs = %{trainer_id: trainer.id, title: "New", slug: "taken-slug", content: "Content"}
      assert {:error, %Ecto.Changeset{}} = Content.create_blog_post(attrs)
    end

    test "create_blog_post/1 with invalid status returns error", %{trainer: trainer} do
      attrs = %{trainer_id: trainer.id, title: "T", slug: "t", content: "C", status: "invalid"}
      assert {:error, %Ecto.Changeset{}} = Content.create_blog_post(attrs)
    end

    test "get_blog_post_by_slug!/1 returns post by slug", %{trainer: trainer} do
      insert(:blog_post, trainer: trainer, slug: "my-post")
      assert %BlogPost{slug: "my-post"} = Content.get_blog_post_by_slug!("my-post")
    end

    test "get_blog_post_for_trainer/2 returns owned post", %{trainer: trainer} do
      post = insert(:blog_post, trainer: trainer)
      assert {:ok, %BlogPost{}} = Content.get_blog_post_for_trainer(post.id, trainer.id)
    end

    test "get_blog_post_for_trainer/2 returns unauthorized for other trainer", %{trainer: trainer} do
      post = insert(:blog_post, trainer: trainer)
      other = insert(:trainer)
      assert {:error, :unauthorized} = Content.get_blog_post_for_trainer(post.id, other.id)
    end

    test "update_blog_post/2 updates the post", %{trainer: trainer} do
      post = insert(:blog_post, trainer: trainer)
      assert {:ok, %BlogPost{status: "published"}} = Content.update_blog_post(post, %{status: "published"})
    end

    test "delete_blog_post/1 deletes the post", %{trainer: trainer} do
      post = insert(:blog_post, trainer: trainer)
      assert {:ok, %BlogPost{}} = Content.delete_blog_post(post)
    end
  end

  describe "testimonials" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      %{trainer: trainer, student: student}
    end

    test "list_testimonials/1 returns testimonials for trainer", %{trainer: trainer, student: student} do
      testimonial = insert(:testimonial, trainer: trainer, student: student)
      assert [%Testimonial{id: id}] = Content.list_testimonials(trainer.id)
      assert id == testimonial.id
    end

    test "create_testimonial/1 with valid data", %{trainer: trainer} do
      attrs = %{
        trainer_id: trainer.id,
        author_name: "Happy Client",
        content: "Best trainer ever!",
        rating: 5
      }

      assert {:ok, %Testimonial{rating: 5}} = Content.create_testimonial(attrs)
    end

    test "create_testimonial/1 with invalid rating returns error", %{trainer: trainer} do
      attrs = %{trainer_id: trainer.id, author_name: "Test", content: "Test", rating: 6}
      assert {:error, %Ecto.Changeset{}} = Content.create_testimonial(attrs)
    end

    test "approve_testimonial/1 approves the testimonial", %{trainer: trainer, student: student} do
      testimonial = insert(:testimonial, trainer: trainer, student: student)
      assert {:ok, %Testimonial{is_approved: true} = approved} = Content.approve_testimonial(testimonial)
      assert approved.approved_at != nil
    end

    test "get_testimonial_for_trainer/2 returns owned testimonial", %{trainer: trainer, student: student} do
      testimonial = insert(:testimonial, trainer: trainer, student: student)
      assert {:ok, %Testimonial{}} = Content.get_testimonial_for_trainer(testimonial.id, trainer.id)
    end

    test "get_testimonial_for_trainer/2 returns unauthorized for other trainer", %{trainer: trainer, student: student} do
      testimonial = insert(:testimonial, trainer: trainer, student: student)
      other = insert(:trainer)
      assert {:error, :unauthorized} = Content.get_testimonial_for_trainer(testimonial.id, other.id)
    end

    test "delete_testimonial/1 deletes the testimonial", %{trainer: trainer, student: student} do
      testimonial = insert(:testimonial, trainer: trainer, student: student)
      assert {:ok, %Testimonial{}} = Content.delete_testimonial(testimonial)
    end
  end

  describe "faqs" do
    setup do
      trainer = insert(:trainer)
      %{trainer: trainer}
    end

    test "list_faqs/1 returns faqs for trainer", %{trainer: trainer} do
      faq = insert(:faq, trainer: trainer)
      assert [%FAQ{id: id}] = Content.list_faqs(trainer.id)
      assert id == faq.id
    end

    test "create_faq/1 with valid data", %{trainer: trainer} do
      attrs = %{
        trainer_id: trainer.id,
        question: "How does it work?",
        answer: "We start with an assessment.",
        category: "getting_started"
      }

      assert {:ok, %FAQ{question: "How does it work?"}} = Content.create_faq(attrs)
    end

    test "create_faq/1 without required fields returns error" do
      assert {:error, %Ecto.Changeset{}} = Content.create_faq(%{})
    end

    test "get_faq_for_trainer/2 returns owned faq", %{trainer: trainer} do
      faq = insert(:faq, trainer: trainer)
      assert {:ok, %FAQ{}} = Content.get_faq_for_trainer(faq.id, trainer.id)
    end

    test "get_faq_for_trainer/2 returns unauthorized for other trainer", %{trainer: trainer} do
      faq = insert(:faq, trainer: trainer)
      other = insert(:trainer)
      assert {:error, :unauthorized} = Content.get_faq_for_trainer(faq.id, other.id)
    end

    test "update_faq/2 updates the faq", %{trainer: trainer} do
      faq = insert(:faq, trainer: trainer)
      assert {:ok, %FAQ{is_published: false}} = Content.update_faq(faq, %{is_published: false})
    end

    test "delete_faq/1 deletes the faq", %{trainer: trainer} do
      faq = insert(:faq, trainer: trainer)
      assert {:ok, %FAQ{}} = Content.delete_faq(faq)
    end
  end
end
