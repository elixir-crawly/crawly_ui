defmodule CrawlyUI.Manager.JobTest do
  use CrawlyUI.DataCase, async: true
  alias CrawlyUI.Manager.Job

  test "job must have spider name" do
    changeset = Job.changeset(%Job{}, %{state: "state", tag: "test", node: "spider@test"})

    assert %{spider: ["can't be blank"]} = errors_on(changeset)
  end

  test "job must have state" do
    changeset = Job.changeset(%Job{}, %{spider: "Crawly.Test", tag: "test", node: "spider@test"})

    assert %{state: ["can't be blank"]} = errors_on(changeset)
  end

  test "job must have tag" do
    changeset =
      Job.changeset(%Job{}, %{state: "state", spider: "Crawly.Test", node: "spider@test"})

    assert %{tag: ["can't be blank"]} = errors_on(changeset)
  end

  test "job must have mode" do
    changeset = Job.changeset(%Job{}, %{state: "state", tag: "test", spider: "Crawly.Test"})

    assert %{node: ["can't be blank"]} = errors_on(changeset)
  end
end
